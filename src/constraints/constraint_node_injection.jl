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

#TODO: can we find an easier way to define the constraint indices?
# I feel that for unexperienced uses it gets more an more complicated to understand our code
"""
    constraint_node_injection_indices()

Forms the stochastic index set for the `:node_injection` constraint.
Uses stochastic path indices due to dynamics and potentially different stochastic
structures between this `node` and `nodes` connected via diffusion.
"""
function constraint_node_injection_indices()
    unique(
        (node=n, stochastic_scenario=path, t_before=t_before, t_after=t_after)
        for (n, tb) in node__temporal_block()
        for t_after in time_slice(temporal_block=tb)
        for t_before in t_before_t(t_after=t_after)
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_node_injection_indices(n, t_after, t_before))
        )
    )
end

"""
    _constraint_node_injection_indices(node, t_after, t_before)

Gathers the current `node_stochastic_time_indices` as well as the relevant `node_state_indices` on the previous
`time_slice` and beyond defined `node__node` relationships for `add_constraint_node_injection!`
"""
function _constraint_node_injection_indices(node, t_after, t_before)
    Iterators.flatten(
        (
            node_stochastic_time_indices(node=node, t=t_after),  # `node` on `t_after`
            node_state_indices(node=node, t=t_before),  # `node_state` on `t_before`
            (
                ind
                for n1 in node__node(node2=node)
                for ind in node_state_indices(node=n1, t=t_after)
            ),  # Diffusion to this `node`
            (
                ind
                for n2 in node__node(node1=node)
                for ind in node_state_indices(node=n2, t=t_after)
            ),  # Diffusion from this `node`
        )
    )
end

"""
    add_constraint_node_injection!(m::Model)

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
