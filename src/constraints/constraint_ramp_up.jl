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
#COPY from unit_state_transition"
"""
    constraint_ramp_up_unit_unit_flow_indices()

Forms the stochastic index set for the `:ramp_up` constraint.
Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""
# function constraint_unit_state_transition_indices()
#     unit_state_transition_indices = []
#     for (u, n) in units_on_resolution()
#         for t_after in time_slice(temporal_block=node__temporal_block(node=n))
#             # Ensure type stability
#             active_scenarios = Array{Object,1}()
#             # `units_on` on `t_after`
#             append!(
#                 active_scenarios,
#                 map(
#                     inds -> inds.stochastic_scenario,
#                     units_on_indices(unit=u, t=t_after)
#                 )
#             )
#             # `units_on` on a valid `t_before`
#             if !isempty(t_before_t(t_after=t_after))
#                 t_before = first(t_before_t(t_after=t_after))
#             else
#                 t_before = first(to_time_slice(t_after - Minute(duration(t_after))))
#             end
#             append!(
#                 active_scenarios,
#                 map(
#                     inds -> inds.stochastic_scenario,
#                     units_on_indices(unit=u, t=t_before)
#                 )
#             )
#             # Find stochastic paths for `active_scenarios`
#             unique!(active_scenarios)
#             for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
#                 push!(
#                     unit_state_transition_indices,
#                     (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
#                 )
#             end
#         end
#     end
#     return unique!(unit_state_transition_indices)
# end
#
# function add_constraint_unit_state_transition!(m::Model)
#     @fetch units_on, units_started_up, units_shut_down = m.ext[:variables]
#     cons = m.ext[:constraints][:unit_state_transition] = Dict()
#     for (u, stochastic_path, t_before, t_after) in constraint_unit_state_transition_indices()
#         cons[u, stochastic_path, t_before, t_after] = @constraint( ...

# Copied from node_injection:
# function constraint_node_injection_indices()
#     node_injection_indices = []
#     for (n, tb) in node__temporal_block()
#         for t_after in time_slice(temporal_block=tb)
#             # Ensure type stability
#             active_scenarios = Array{Object,1}()
#             # Find a valid `t_before`
#             if !isempty(t_before_t(t_after=t_after))
#                 t_before = first(t_before_t(t_after=t_after))
#             else
#                 t_before = first(to_time_slice(t_after - Minute(duration(t_after))))
#             end
#             # `node` on `t_after`
#             append!(
#                 active_scenarios,
#                 map(
#                     inds -> inds.stochastic_scenario,
#                     node_stochastic_time_indices(node=n, t=t_after)
#                 )
#             )
#             # `node_state` on `t_before`
#             append!(
#                 active_scenarios,
#                 map(
#                     inds -> inds.stochastic_scenario,
#                     node_state_indices(node=n, t=t_before)
#                 )
#             )
#             # Diffusion to this `node`
#             for (n_, n) in node__node(node2=n)
#                 append!(
#                     active_scenarios,
#                     map(
#                         inds -> inds.stochastic_scenario,
#                         node_state_indices(node=n_, t=t_after)
#                     )
#                 )
#             end
#             # Diffusion from this `node`
#             for (n, n_) in node__node(node1=n)
#                 append!(
#                     active_scenarios,
#                     map(
#                         inds -> inds.stochastic_scenario,
#                         node_state_indices(node=n_, t=t_after)
#                     )
#                 )
#             end
#             # Commodity unit_flows to/from `units` aren' needed as they use same structures as the `node`
#             # Find stochastic paths for `active_scenarios`
#             unique!(active_scenarios)
#             for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
#                 push!(
#                     node_injection_indices,
#                     (node=n, stochastic_scenario=path, t_before=t_before, t_after=t_after)
#                 )
#             end
#         end
#     end
#     return unique!(node_injection_indices)
# end
#
# function add_constraint_node_injection!(m::Model)
#     @fetch node_injection, node_state, unit_unit_flow = m.ext[:variables]
#     cons = m.ext[:constraints][:node_injection] = Dict()
#     for (n, stochastic_path, t_before, t_after) in constraint_node_injection_indices()
#         cons[n, stochastic_path, t_before, t_after] = @constraint(...


#TODO: stochastic_path, stoachstics
# Stochastic path for unit_flow -> unit_flow before
"""
    add_constraint_ramp_up!(m::Model)

Limit the maximum ramp of `unit_flow` of a `unit` if the parameters
`ramp_up_limit,unit_capacity,unit_conv_cap_to_unit_flow, minimum_operating_point` exist.
"""

function add_constraint_ramp_up!(m::Model)
    @fetch unit_flow, units_on,  units_started_up, ramp_up_unit_flow, start_up_unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:ramp_up] = Dict()
    for (u, c, d) in intersect(indices(ramp_up_limit),indices(unit_capacity))
            for (u, t_after) in units_on_indices(unit=u)
                    for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
                    constr_dict[u, c, d, t_after] = @constraint(
                        m,
                        + sum(
                            ramp_up_unit_flow[u, n, d, s, t]
                                    for (u, n, d, s, t) in ramp_up_unit_flow_indices(unit=u, node=n, direction = d, t=t_before)
                        ) #TODO: make sure that upward_spinning are included here!
                        # + sum(
                        #     unit_flow[u, n, d, s, t]
                        #             for (u, n, d, s, t) in unit_flow_indices(unit=u, commodity=c, direction = d, t=t_before)
                        #                 if reserve_node_type(node=n) == :upward_spinning)
                        #                     #TODO add this as a ramp too!
                        #                     #instead of having separater res_ramp_up include here
                        <=
                        + (units_on[u, t_after] - units_started_up[u,t_after])
                             * ramp_up_limit[(unit=u, node=n, direction=d, t=t)] *unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)] *unit_capacity[(unit=u, commodity=c, direction=d)]
                             #TODO add scenario parameter values
                    )
            end
        end
    end
end
