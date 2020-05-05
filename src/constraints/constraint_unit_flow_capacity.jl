#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
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
    unit_flow_capacity_indices = []
    for (u, n, d) in indices(unit_capacity)
        for t in time_slice(temporal_block=node__temporal_block(node=n))
            # Constrained `unit_flow`
            active_scenarios = unit_flow_indices_rc(unit=u, node=n, direction=d, t=t, _compact=true)
            # Relevant `units_on`
            append!(
                active_scenarios,
                units_on_indices_rc(unit=u, t=t_in_t(t_long=t), _compact=true)
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    unit_flow_capacity_indices,
                    (unit=u, node=n, direction=d, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(unit_flow_capacity_indices)
end


"""
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_flow_capacity] = Dict()
    for (u, n, d, stochastic_path, t) in constraint_unit_flow_capacity_indices()
        cons[u, n, d, stochastic_path, t] = @constraint(
            m,
            reduce(
                +,
                get(unit_flow, (u, n, d, s, t), 0)
                for s in stochastic_path;
                init=0
            ) * duration(t)
            <=
            + unit_capacity[(unit=u, node=n, direction=d, t=t)] # TODO: Stochastic parameters
            * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
            * reduce(
                +,
                units_on[u, s, t_short] * duration(t_short)
                for (u, s, t_short) in units_on_indices(unit=u, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t));
                init=0
            )
        )
    end
end
