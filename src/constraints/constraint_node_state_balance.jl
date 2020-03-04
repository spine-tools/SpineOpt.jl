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
    add_constraint_node_state_balance!(m::Model)

Balance equation for node state.
"""
function add_constraint_node_state_balance!(m::Model)
    @fetch node_state, trans, flow = m.ext[:variables]
    cons = m.ext[:constraints][:node_state_balance] = Dict()
    for (n, t_after) in node_state_indices()
        for (n, t_before) in node_state_indices(node=n, commodity=c, t=t_before_t(t_after=t_after))
            cons[n, t_before, t_after] = @constraint(
                m,
                # Change in node commodity content
                (
                    node_state[n, t_after] * state_coeff(node=n, t=t_after)
                    - node_state[n, t_before] * state_coeff(node=n, t=t_before)   
                )
                    / duration(t_after)
                ==
                # Self-discharge commodity losses
                - node_state[n, t_after] * frac_state_loss(node=n, t=t_after)
                # Diffusion of commodity from this node to other nodes
                - reduce(
                    +,
                    node_state[n, t_after]
                    * diff_coeff(node1=n, node2=n_, t=t_after)
                    for n_ in node__node(node1=n);
                    init = 0
                )
                # Diffusion of commodity from other nodes to this one
                + reduce(
                    +,
                    node_state[n_, t_after]
                    * diff_coeff(node1=n_, node2=n, t=t_after)
                    for n_ in node__node(node2=n);
                    init = 0
                )
                # Commodity flows from units
                + reduce(
                    +,
                    flow[u, n, c, d, t1]
                    for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:to_node));
                    init=0
                )
                # Commodity flows to units
                - reduce(
                    +,
                    flow[u, n, c, d, t1]
                    for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:from_node));
                    init=0
                )
                # Commodity transfers from connections
                + reduce(
                    +,
                    trans[conn, n, c, d, t1]
                    for (conn, n, c, d, t1) in trans_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:to_node));
                    init=0
                )
                # Commodity transfers to connections
                - reduce(
                    +,
                    trans[conn, n, c, d, t1]
                    for (conn, n, c, d, t1) in trans_indices(node=n, t=t_in_t(t_long=t_after), direction=direction(:from_node));
                    init=0
                )
                # Demand for the commodity
                - demand(node=n, t=t_after)
            )
        end
    end
end

function update_constraint_node_state_balance!(m::Model)
    @fetch node_state, trans, flow = m.ext[:variables]
    cons = m.ext[:constraints][:node_state_balance]
    for (n, t_after) in node_state_indices()
        for (n, t_before) in node_state_indices(node=n, t=t_before_t(t_after=t_after))
            # Update this node's node_state(t_after) coefficient
            set_normalized_coefficient(
                cons[n, t_before, t_after],
                node_state[n, t_after],
                + state_coeff(node=n, t=t_after) / duration(t_after)
                + frac_state_loss(node=n, t=t_after)
                + reduce(
                    +,
                    diff_coeff(node1=n, node2=n_, t=t_after)
                    for n_ in node__node(node1=n);
                    init = 0
                )
            )
            # Update this node's node_state(t_before) coefficient
            set_normalized_coefficient(
                cons[n, t_before, t_after],
                node_state[n, t_before],
                - state_coeff(node=n, t=t_before) / duration(t_after)
            )
            # Update coefficients for connected node_states
            for n_ in node__node(node2=n)
                set_normalized_coefficient(
                    cons[n, t_before, t_after],
                    node_state[n_, t_after],
                    - diff_coeff(node1=n_, node2=n, t=t_after)
                )
            end
            # Update demand
            set_normalized_rhs(
                cons[n, t_before, t_after],
                - demand(node=n, t=t_after)
            )
        end
    end
end