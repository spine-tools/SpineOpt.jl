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
    constraint_min_nonspin_ramp_up_indices()

Forms the stochastic index set for the `:min_start_up_ramp` constraint.
Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""
function constraint_min_start_up_ramp_indices()
    constraint_indices = []
    for (u, n, d) in indices(min_startup_ramp)
        for t in t_lowest_resolution(x.t for x in start_up_unit_flow_indices(unit=u,node=n,direction=d))
            #NOTE: we're assuming that the ramp constraint follows the resolution of flows
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # `start_up_unit_flow` for `direction` `d`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    start_up_unit_flow_indices(unit=u, node=n, direction=d, t=t_in_t(t_long=t))
                )
            )
            # `units_started_up`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    units_started_up_indices(unit=u, node=n, t=t_in_t(t_long=t))
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    constraint_indices,
                    (unit=u, node=n, direction=d, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(constraint_indices)
end
"""
    add_constraint_min_start_up_ramp!(m::Model)

Limit the minimum ramp at the start up of a unit. For reserves the min non-spinning
reserve ramp can be defined here.
"""
function add_constraint_min_start_up_ramp!(m::Model)
    @fetch units_started_up, start_up_unit_flow = m.ext[:variables]
    cons = m.ext[:constraints][:min_start_up_ramp] = Dict()
    for (u, ng, d, s, t) in constraint_min_start_up_ramp_indices()
        cons[u, ng, d, s, t] = @constraint(
            m,
            + sum(
                start_up_unit_flow[u, n, d, s, t]
                        for (u, n, d, s, t) in start_up_unit_flow_indices(
                            unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(t_long=t))
            )
            <=
            + sum(
                units_started_up[u, s, t]
                        for (u, s, t) in units_on_indices(unit=u, stochastic_scenario=s, t=t_overlaps_t(t))
            )
                * min_startup_ramp[(unit=u, node=ng, direction=d)]
                    * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, t=t)]
                        *unit_capacity[(unit=u, node=ng, direction=d, t=t)]
        )
    end
end
