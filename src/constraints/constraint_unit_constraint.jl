#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    constraint_unit_constraint_indices()

Forms the stochastic index set for the `:unit_constraint` constraint. Uses
stochastic path indices due to potentially different stochastic structures 
between `unit_flow`, `unit_flow_op`, and `units_on` variables.
"""
function constraint_unit_constraint_indices()
    unique(
        (unit_constraint=uc, stochastic_scenario=path, t=t)
        for uc in unit_constraint()
        for t in _constraint_unit_constraint_lowest_resolution_t(uc)
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_unit_constraint_indices(uc, t))
        )
    )
end

function _constraint_unit_constraint_lowest_resolution_t(unit_constraint)
    t_lowest_resolution(
        ind.t
        for unit__node__unit_constraint in (unit__from_node__unit_constraint, unit__to_node__unit_constraint)
        for (u, n) in unit__node__unit_constraint(unit_constraint=unit_constraint)
        for ind in unit_flow_indices(unit=u, node=n)
    )
end

function _constraint_unit_constraint_unit_flow_indices(unit_constraint, t)
    (
        ind
        for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
        for ind in unit_flow_indices(unit=u, node=n, direction=direction(:from_node), t=t_in_t(t_long=t))
    )
end

function _constraint_unit_constraint_units_on_indices(unit_constraint, t)
    (ind for u in unit__unit_constraint(unit_constraint=uc) for ind in units_on_indices(unit=u, t=t_in_t(t_long=t)))
end

function _constraint_unit_constraint_indices(unit_constraint, t)
    Iterators.flatten(
        (
            _constraint_unit_constraint_unit_flow_indices(unit_constraint, t),
            _constraint_unit_constraint_units_on_indices(unit_constraint, t)
        )
    )
end

"""
    add_constraint_unit_constraint(m::Model)

Custom constraint for `units`.
"""
function add_constraint_unit_constraint!(m::Model)
    @fetch unit_flow_op, unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_constraint] = Dict()
    for (uc, stochastic_path, t) in constraint_unit_constraint_indices()
        cons[uc, stochastic_path, t] = sense_constraint(
            m,
            + expr_sum(
                + unit_flow_op[u, n, d, op, s, t_short]
                * unit_flow_coefficient[(unit=u, node=n, unit_constraint=uc, i=op, t=t_short)]
                * duration(t_short)
                for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    unit=u,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=stochastic_path,
                    t=t_in_t(t_long=t)
                );
                init=0
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t_short]
                * unit_flow_coefficient[(unit=u, node=n, unit_constraint=uc, i=1, t=t_short)]
                * duration(t_short)
                for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    unit=u,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=stochastic_path,
                    t=t_in_t(t_long=t)
                )
                if isempty(unit_flow_op_indices(unit=u, node=n, direction=d, t=t_short));
                init=0
            )
            + expr_sum(
                + unit_flow_op[u, n, d, op, s, t_short]
                * unit_flow_coefficient[(unit=u, node=n, unit_constraint=uc, i=op, t=t_short)]
                * duration(t_short)
                for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    unit=u,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=stochastic_path,
                    t=t_in_t(t_long=t)
                );
                init=0
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t_short]
                * unit_flow_coefficient[(unit=u, node=n, unit_constraint=uc, i=1, t=t_short)]
                * duration(t_short)
                for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    unit=u,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=stochastic_path,
                    t=t_in_t(t_long=t)
                )
                if isempty(unit_flow_op_indices(unit=u, node=n, direction=d, t=t_short));
                init=0
            )
            + expr_sum(
                + units_on[u, s, t1]
                * units_on_coefficient[(unit_constraint=uc, unit=u, t=t1)]
                * min(duration(t1),duration(t))
                for u in unit__unit_constraint(unit_constraint=uc)
                for (u, s, t1) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_overlaps_t(t)
                );
                init=0
            ),
            constraint_sense(unit_constraint=uc),
            + right_hand_side(unit_constraint=uc, t=t),
        )
    end
end
