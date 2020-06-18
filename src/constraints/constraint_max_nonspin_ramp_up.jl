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
    constraint_max_nonspin_ramp_up_indices()

Forms the stochastic index set for the `:max_nonspin_start_up_ramp` constraint.
Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""
function constraint_max_nonspin_ramp_up_indices()
    constraint_indices = []
    for (u, n, d) in indices(max_res_startup_ramp)
        for t in t_lowest_resolution(x.t for x in nonspin_ramp_up_unit_flow_indices(unit=u,node=n,direction=d))
            #NOTE: we're assuming that the ramp constraint follows the resolution of flows
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # `nonspin_ramp_up_unit_flow` for `direction` `d`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    nonspin_ramp_up_unit_flow_indices(unit=u, node=n, direction=d, t=t_in_t(t_long=t))
                )
            )
            # `nonspin_starting_up`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    nonspin_starting_up_indices(unit=u, node=n, t=t_in_t(t_long=t))
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
    add_constraint_max_nonspin_start_up_ramp!(m::Model)

Limit the maximum ramp at the start up of a unit. For reserves the max non-spinning
reserve ramp can be defined here.
"""
function add_constraint_max_nonspin_ramp_up!(m::Model)
    @fetch nonspin_ramp_up_unit_flow, nonspin_starting_up = m.ext[:variables]
    cons = m.ext[:constraints][:max_nonspin_start_up_ramp] = Dict()
    for (u, ng, d, s, t) in constraint_max_nonspin_ramp_up_indices()
        cons[u, ng, d, s, t] = @constraint(
            m,
            + sum(
                nonspin_ramp_up_unit_flow[u, n, d, s, t]
                        for (u, n, d, s, t) in nonspin_ramp_up_unit_flow_indices(
                            unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(t_long=t))
            )
            <=
            + expr_sum(
                nonspin_starting_up[u, n, s, t]
                        for (u, n, s, t) in nonspin_starting_up_indices(
                            unit=u, node=ng, stochastic_scenario=s, t=t_overlaps_t(t));
                            init=0
            )
                * max_res_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)]
        )
    end
end
