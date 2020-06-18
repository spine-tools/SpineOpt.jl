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
#TODO: support nodal balance sense
#TODO: as proposed in the wiki on groups: We should be able to support
# a) node_balance for node group and NO balance for underlying node
# b) node_balance for node group AND balance for underlying node
"""
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.
"""
function add_constraint_nodal_balance!(m::Model)
    @fetch node_injection, connection_flow, node_slack_pos, node_slack_neg = m.ext[:variables]
    cons = m.ext[:constraints][:nodal_balance] = Dict()
    for (n, s, t) in node_stochastic_time_indices()
        # Skip nodes that are part of a node group having balance_type_group
        (any(balance_type(node=ng) === :balance_type_group for ng in node_group__node(node2=n)) || (nodal_balance_sense(node=n) == :none)) && continue
        cons[n, s, t] = sense_constraint(
            m,
            # Net injection
            + node_injection[n, s, t]
            # Commodity flows from connections
            + expr_sum(
                connection_flow[conn, n, d, s, t]
                for (conn, n, d, s, t) in connection_flow_indices(
                    node=n, direction=direction(:to_node), stochastic_scenario=s, t=t
                )
                if !(balance_type(node=n) === :balance_type_group && _is_internal(conn, n));
                    #TODO: what would be the meaning of balance_type(node=n) != :balance_type_group but is internal?
                    # this should not be allowed I guess? I think !(_is_internal) should be sufficient
                init=0
            )
            # Commodity flows to connections
            - expr_sum(
                connection_flow[conn, n, d, s, t]
                for (conn, n, d, s, t) in connection_flow_indices(
                    node=n, direction=direction(:from_node), stochastic_scenario=s, t=t
                )
                if !(balance_type(node=n) === :balance_type_group && _is_internal(conn, n));
                init=0
            )
            # slack variable - only exists if slack_penalty is defined
            + get(node_slack_pos, (n, s, t), 0)
            - get(node_slack_neg, (n, s, t), 0)
            ,
            eval(nodal_balance_sense(node=n))
            ,
            0
        )
    end
end

"""
    _is_internal(conn, ng)

Determine whether or not a `connection` is internal to a `node_group`, in the sense that it only connects `nodes`
within that `node_group`.
"""
_is_internal(conn, ng) = issubset(_connection_nodes(conn), node_group__node(node1=ng))

"""
    _connection_nodes(conn)

An iterator over all `nodes` of a `connection`.
"""
_connection_nodes(conn) = (
    n
    for connection__node in (connection__from_node, connection__to_node)
    for n in connection__node(connection=conn, direction=anything)
)
