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
    @fetch node_state, trans, flow = m.ext[:variables]
    cons = m.ext[:constraints][:nodal_balance] = Dict()
    for (n, t_after) in node_state_indices()
        for (n, t_before) in node_state_indices(node=n, t=t_before_t(t_after=t_after))
            cons[n, t_before, t_after] = @constraint(
                m,
                # Change in node state
                (
                    node_state[n, t_after] * state_coeff(node=n, t=t_after)
                    - node_state[n, t_before] * state_coeff(node=n, t=t_before)
                )
                    / duration(t_after)
                ==
                # Self-discharge losses
                - node_state[n, t_after] * frac_state_loss(node=n, t=t_after)
                # Diffusion from this node to other nodes
                - reduce(
                    +,
                    node_state[n, t_after]
                    * diff_coeff(node1=n, node2=n_, t=t_after)
                    for n_ in node__node(node1=n);
                    init = 0
                )
                # Diffusion from other nodes to this one
                + reduce(
                    +,
                    node_state[n_, t_after]
                    * diff_coeff(node1=n_, node2=n, t=t_after)
                    for n_ in node__node(node2=n);
                    init = 0
                )
                # Flows from units
                + reduce(
                    +,
                    flow[u, n, d, t1]
                    for (u, n, d, t1) in flow_indices(node=n, direction=direction(:to_node), t=t_in_t(t_long=t_after));
                    init=0
                )
                # Flows to units
                - reduce(
                    +,
                    flow[u, n, d, t1]
                    for (u, n, d, t1) in flow_indices(node=n, direction=direction(:from_node), t=t_in_t(t_long=t_after));
                    init=0
                )
                # Transfers from connections
                + reduce(
                    +,
                    trans[conn, n, d, t1]
                    for (conn, n, d, t1) in trans_indices(node=n, direction=direction(:to_node), t=t_in_t(t_long=t_after));
                    init=0
                )
                # Transfers to connections
                - reduce(
                    +,
                    trans[conn, n, d, t1]
                    for (conn, n, d, t1) in trans_indices(node=n, direction=direction(:from_node), t=t_in_t(t_long=t_after));
                    init=0
                )
                # Exogenous demand
                - demand[(node=n, t=t_after)]
            )
        end
    end
end