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
    constraint_unit_flow_capacity_indices()

Forms the stochastic index set for the `:unit_flow_capacity` constraint.
Uses stochastic path indices due to potentially different stochastic structures
between `unit_flow` and `units_on` variables.
"""
function constraint_unit_flow_capacity_indices()
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity)
        # TODO: do we need to expand groups here? We still get the 'groups' out of `indices(unit_capacity)`,
        # and then we feed them to `unit_flow_indices` in the constraint below (at which point they get expanded).
        for t in time_slice(temporal_block=node__temporal_block(node=expand_node_group(ng)))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_unit_flow_capacity_indices(u, ng, d, t))
        )
    )
end

"""
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_flow_capacity] = Dict()
    for (u, ng, d, stochastic_path, t) in constraint_unit_flow_capacity_indices()
        cons[u, ng, d, stochastic_path, t] = @constraint(
            m,
            expr_sum(
                + unit_flow[u, n, d, s, t]
                for (u, n, d, s, t) in setdiff(
                    unit_flow_indices(
                    unit=u, node=ng, direction=d, stochastic_scenario=stochastic_path, t=t
                    ),
                    nonspin_ramp_up_unit_flow_indices(
                    unit=u, node=ng, direction=d, stochastic_scenario=stochastic_path, t=t
                    )
                    );
                init=0
            ) * duration(t)
            <=
            + unit_capacity[(unit=u, node=ng, direction=d, t=t)] # TODO: Stochastic parameters
            * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, t=t)]
            * expr_sum(
                units_on[u, s, t1] * min(duration(t1),duration(t))
                for (u, s, t1) in units_on_indices(unit=u, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t));
                    #This should be:t=t_overlaps_t(t), but broken for now!
                init=0
            )
        )
    end
end
