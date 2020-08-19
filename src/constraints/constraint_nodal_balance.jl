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
# TODO: support nodal balance sense
# TODO: as proposed in the wiki on groups: We should be able to support
# a) node_balance for node group and NO balance for underlying node
# b) node_balance for node group AND balance for underlying node

"""
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.
"""
function add_constraint_nodal_balance!(m::Model)
    @fetch node_injection, connection_flow, node_slack_pos, node_slack_neg = m.ext[:variables]
    m.ext[:constraints][:nodal_balance] = Dict(
        (n, s, t) => sense_constraint(
            m,
            # Net injection
            + node_injection[n, s, t]
            # Commodity flows from connections
            + expr_sum(
                connection_flow[conn, n, d, s, t]
                for (conn, n, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t
                )
                if !issubset(_connection_nodes(conn), internal_nodes);
                init=0
            )
            # Commodity flows to connections
            - expr_sum(
                connection_flow[conn, n, d, s, t]
                for (conn, n, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:from_node), stochastic_scenario=s, t=t
                )
                if !issubset(_connection_nodes(conn), internal_nodes);
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
        for (n, internal_nodes, s, t) in (
            (n, _internal_nodes(n), s, t)
            for (n, s, t) in node_stochastic_time_indices(m)
            if nodal_balance_sense(node=n) !== :none
            && all(balance_type(node=ng) !== :balance_type_group for ng in groups(n))
        )
    )
end

_internal_nodes(n::Object) = balance_type(node=n) === :balance_type_group ? members(n) : []

"""
    _connection_nodes(conn)

An iterator over all `nodes` of a `connection`.
"""
_connection_nodes(conn::Object) = (
    n
    for connection__node in (connection__from_node, connection__to_node)
    for n in connection__node(connection=conn, direction=anything)
)
