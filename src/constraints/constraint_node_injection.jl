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
    constraint_node_injection_indices()

Forms the stochastic index set for the `:node_injection` constraint.
Uses stochastic path indices due to dynamics and potentially different stochastic
structures between this `node` and `nodes` connected via diffusion.
"""
function constraint_node_injection_indices()
    node_injection_indices = []
    for (n, tb) in node__temporal_block()
        for t_after in time_slice(temporal_block=tb)
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # Find a valid `t_before`
            if !isempty(t_before_t(t_after=t_after))
                t_before = first(t_before_t(t_after=t_after))
            else
                t_before = first(to_time_slice(t_after - Minute(duration(t_after))))
            end
            # `node` on `t_after`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    node_stochastic_time_indices(node=n, t=t_after)
                )
            )
            # `node_state` on `t_before`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    node_state_indices(node=n, t=t_before)
                )
            )
            # Diffusion to this `node`
            for (n_, n) in node__node(node2=n)
                append!(
                    active_scenarios,
                    map(
                        inds -> inds.stochastic_scenario,
                        node_state_indices(node=n_, t=t_after)
                    )
                )
            end
            # Diffusion from this `node`
            for (n, n_) in node__node(node1=n)
                append!(
                    active_scenarios,
                    map(
                        inds -> inds.stochastic_scenario,
                        node_state_indices(node=n_, t=t_after)
                    )
                )
            end
            # Commodity flows to/from `units` aren' needed as they use same structures as the `node`
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    node_injection_indices,
                    (node=n, stochastic_scenario=path, t_before=t_before, t_after=t_after)
                )
            end
        end
    end
    return unique!(node_injection_indices)
end


"""
    add_constraint_node_injection(m::Model)

Set the node injection equal to the summation of all 'input' flows but connection's.
"""
function add_constraint_node_injection!(m::Model)
    @fetch node_injection, node_state, unit_flow = m.ext[:variables]
    cons = m.ext[:constraints][:node_injection] = Dict()
    #TODO: We need to include both: storages that are defined on ng and storage that are defined
    #on internal nodes
    for (ng, stochastic_path, t_before, t_after) in constraint_node_injection_indices()
        cons[ng, stochastic_path, t_before, t_after] = @constraint(
            m,
            + expr_sum(
                + node_injection[ng, s, t_after]
                for (ng, s, t_after) in node_injection_indices(
                    node=ng, stochastic_scenario=stochastic_path, t=t_after
                );
                init=0
            )
            ==
            + expr_sum(
                (
                    + get(node_state, (ng, s, t_before), 0) * state_coeff[(node=ng, t=t_before)]
                    - get(node_state, (ng, s, t_after), 0) * state_coeff[(node=ng, t=t_after)]
                )
                / duration(t_after)
                # Self-discharge commodity losses
                - get(node_state, (ng, s, t_after), 0) * frac_state_loss[(node=ng, t=t_after)]
                for s in stochastic_path;
                init=0
            )
            # Diffusion of commodity from other nodes to this one
            + expr_sum(
                get(node_state, (n_, s, t_after), 0) * diff_coeff[(node1=n_, node2=ng, t=t_after)]
                for n_ in node__node(node2=ng)
                for s in stochastic_path;
                init=0
            )
            # Diffusion of commodity from this node to other nodes
            - expr_sum(
                get(node_state, (ng, s, t_after), 0) * diff_coeff[(node1=ng, node2=n_, t=t_after)]
                for n_ in node__node(node1=ng)
                for s in stochastic_path;
                init=0
            )
            # Commodity flows from units
            + expr_sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    node=ng, direction=direction(:to_node), stochastic_scenario=stochastic_path, t=t_in_t(t_long=t_after)
                );
                init=0
            )
            # Commodity flows to units
            - expr_sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    node=ng, direction=direction(:from_node), stochastic_scenario=stochastic_path, t=t_in_t(t_long=t_after)
                );
                init=0
            )
            - demand[(node=ng, t=t_after)]
            - expr_sum(
                fractional_demand[(node1=ng_, node2=ng, t=t_after)] * demand[(node=ng_, t=t_after)]
                for ng_ in node_group__node(node2=ng);
                init=0
            )
            #TODO: fractional_demand etc. are scneario dependent?
        )
    end
end
