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
    constraint_ratio_unit_flow_indices(ratio, d1, d2)

Forms the stochastic index set for the `:ratio_unit_flow` constraint for the
desired `ratio` and direction pair `d1` and `d2`. Uses stochastic path indices
due to potentially different stochastic structures between `unit_flow` and
`units_on` variables.
"""
function constraint_ratio_unit_flow_indices(ratio, d1, d2)
    unique(
        (unit=u, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (u, n1, n2) in indices(ratio)
        for t in t_lowest_resolution(x.t for x in unit_flow_indices(unit=u, node=[n1, n2]))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_ratio_unit_flow_indices(u, n1, d1, n2, d2, t))
        )
    )
end

"""
    _constraint_ratio_unit_flow_indices(unit, node1, direction1, node2, direction2, t)

Gather the indices of the relevant `unit_flow` and `units_on` variables.
"""
function _constraint_ratio_unit_flow_indices(unit, node1, direction1, node2, direction2, t)
    Iterators.flatten(
        (
            unit_flow_indices(unit=unit, node=node1, direction=direction1, t=t_in_t(t_long=t)),
            unit_flow_indices(unit=unit, node=node2, direction=direction2, t=t_in_t(t_long=t)),
            units_on_indices(unit=unit, t=t_in_t(t_long=t))
        )
    )    
end

"""
    add_constraint_ratio_unit_flow!(m, ratio, sense, d1, d2)

Ratio of `unit_flow` variables.
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio, units_on_coefficient, sense, d1, d2)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][ratio.name] = Dict()
    for (u, ng1, ng2, stochastic_path, t) in constraint_ratio_unit_flow_indices(ratio, d1, d2)
        cons[u, ng1, ng2, stochastic_path, t] = sense_constraint(
            m,
            + expr_sum(
                unit_flow[u, n1, d1, s, t_short] * duration(t_short)
                for (u, n1, d1, s, t_short) in unit_flow_indices(
                    unit=u, node=ng1, direction=d1, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t)
                );
                init=0
            )
            ,
            sense,
            + ratio[(unit=u, node1=ng1, node2=ng2, t=t)]
            * expr_sum(
                unit_flow[u, n2, d2, s, t_short] * duration(t_short)
                for (u, n2, d2, s, t_short) in unit_flow_indices(
                    unit=u, node=ng2, direction=d2, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t)
                );
                init=0
            )
            + units_on_coefficient[(unit=u, node1=ng1, node2=ng2, t=t)]
            * expr_sum(
                units_on[u, s, t1] * min(duration(t1), duration(t))
                for (u, s, t1) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_overlaps_t(t)
                );
                init=0
            ),
        )
    end
end

"""
    add_constraint_fix_ratio_out_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_in_unit_flow, fix_units_on_coefficient_out_in, ==, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_in_unit_flow, max_units_on_coefficient_out_in, <=, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_min_ratio_out_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_out_in_unit_flow, min_units_on_coefficient_out_in, >=, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_fix_ratio_in_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_in_unit_flow, fix_units_on_coefficient_in_in, ==, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_in_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_in_unit_flow, max_units_on_coefficient_in_in, <=, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_min_ratio_in_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_in_in_unit_flow, min_units_on_coefficient_in_in, >=, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_out_unit_flow, fix_units_on_coefficient_out_out, ==, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_max_ratio_out_out_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_out_unit_flow, max_units_on_coefficient_out_out, <=, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_min_ratio_out_out_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_out_out_unit_flow, min_units_on_coefficient_out_out, >=, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_fix_ratio_in_out_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_out_unit_flow, fix_units_on_coefficient_in_out, ==, direction(:from_node), direction(:to_node)
    )
end

"""
    add_constraint_max_ratio_in_out_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_out_unit_flow, max_units_on_coefficient_in_out, <=, direction(:from_node), direction(:to_node)
    )
end

"""
    add_constraint_min_ratio_in_out_unit_flow!(m::Model)

Calls `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_in_out_unit_flow, min_units_on_coefficient_in_out, >=, direction(:from_node), direction(:to_node)
    )
end
