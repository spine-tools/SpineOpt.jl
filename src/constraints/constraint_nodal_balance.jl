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
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.
"""
function add_constraint_nodal_balance!(m::Model)
    @fetch node_state, connection_flow, unit_flow, node_slack_pos, node_slack_neg = m.ext[:variables]
    cons = m.ext[:constraints][:nodal_balance] = Dict()

#   Supress the node-balance constraint for nodes that are part of a node_group which has balance_type=balance_type_group set
#   node_balance_nodes[] will contain the set of nodes less those for which the above is true
    node_balance_nodes=[]
    for n in node()
        if balance_type(node=n) != :balance_type_group
            if isempty(node_group__node(node2=n))
                push!(node_balance_nodes,n)
            else
                for ng in node_group__node(node2=n)
                    if balance_type(node=ng) != :balance_type_group
                        push!(node_balance_nodes,n)
                    end
                end
            end
        end
    end

    for n in node_balance_nodes
        for tb in node__temporal_block(node=n)
            for t_after in time_slice(temporal_block=tb)
                for t_before in t_before_t(t_after=t_after)
                    cons[n, t_before, t_after] = @constraint(
                        m,
                        # Change in node commodity content
                        (
                            get(node_state, (n, t_after), 0) * state_coeff[(node=n, t=t_after)]
                            - get(node_state, (n, t_before), 0) * state_coeff[(node=n, t=t_before)]
                        )
                            / duration(t_after)
                        ==
                        # Self-discharge commodity losses
                        - get(node_state, (n, t_after), 0) * frac_state_loss[(node=n, t=t_after)]
                        # Diffusion of commodity from this node to other nodes
                        - reduce(
                            +,
                            get(node_state, (n, t_after), 0)
                            * diff_coeff[(node1=n, node2=n_, t=t_after)]
                            for n_ in node__node(node1=n);
                            init = 0
                        )
                        # Diffusion of commodity from other nodes to this one
                        + reduce(
                            +,
                            get(node_state, (n_, t_after), 0)
                            * diff_coeff[(node1=n_, node2=n, t=t_after)]
                            for n_ in node__node(node2=n);
                            init = 0
                        )
                        # Commodity flows from units
                        + reduce(
                            +,
                            unit_flow[u, n, d, t1]
                            for (u, n, d, t1) in unit_flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:to_node));
                            init=0
                        )
                        # Commodity flows to units
                        - reduce(
                            +,
                            unit_flow[u, n, d, t1]
                            for (u, n, d, t1) in unit_flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:from_node));
                            init=0
                        )
                        # Commodity flows from connections
                        + reduce(
                            +,
                            connection_flow[conn, n, d, t1]
                            for (conn, n, d, t1) in connection_flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:to_node));
                            init=0
                        )
                        # Commodity flows to connections
                        - reduce(
                            +,
                            connection_flow[conn, n, d, t1]
                            for (conn, n, d, t1) in connection_flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:from_node));
                            init=0
                        )
                        # Explicit nodal demand
                        - demand[(node=n, t=t_after)]
                        # Fractional demand
                        - reduce(
                            +,
                            fractional_demand[(node1=ng, node2=n, t=t_after)] * demand[(node=ng, t=t_after)]
                            for ng in node_group__node(node2=n);
                            init=0
                        )
                        # slack variable - only exists if slack_penalty is defined
                        + get(node_slack_pos, (n, t_after), 0)
                        - get(node_slack_neg, (n, t_after), 0)
                    )
                end
            end
        end
    end
end
