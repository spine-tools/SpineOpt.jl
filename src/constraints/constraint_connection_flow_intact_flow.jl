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

"""
    add_constraint_connection_flow_intact_flow!(m::Model)

Enforces the relationship between `connection_intact_flow` (flow with all investments assumed in force) and 
`connection_flow`

`connection_intact_flow` is the flow on all lines with all investments assumed in place. This constraint ensures that the
`connection_flow` is the `intact_flow` plus additional contributions from all investments not invested in.
"""
function add_constraint_connection_flow_intact_flow!(m::Model)
    @fetch connection_flow, connection_intact_flow = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:connection_flow_intact_flow] = Dict(
        (connection=conn, node=ng, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + connection_flow[conn, n, direction(:from_node), s, t] * duration(t)
                - connection_flow[conn, n, direction(:to_node), s, t] * duration(t)
                - connection_intact_flow[conn, n, direction(:from_node), s, t] * duration(t)
                + connection_intact_flow[conn, n, direction(:to_node), s, t] * duration(t)
                for (conn, n, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    direction=direction(:from_node),
                    node=ng,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            ==
            + expr_sum(
                lodf(connection1=candidate_conn, connection2=conn) * (
                    + connection_intact_flow[candidate_conn, n, direction(:from_node), s, t] * duration(t)
                    - connection_intact_flow[candidate_conn, n, direction(:to_node), s, t] * duration(t)
                    - connection_flow[candidate_conn, n, direction(:from_node), s, t] * duration(t)
                    + connection_flow[candidate_conn, n, direction(:to_node), s, t] * duration(t)
                ) for candidate_conn in _candidate_connections(conn)
                for n in last(connection__from_node(connection=candidate_conn))
                for (candidate_conn, n, d, s, t) in connection_flow_indices(
                    m;
                    connection=candidate_conn,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
        ) for (conn, ng, s, t) in constraint_connection_flow_intact_flow_indices(m)
    )
end

function constraint_connection_flow_intact_flow_indices(m::Model)
    unique(
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true, is_candidate=false)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn; _compact=false), 1)
        for t in _constraint_connection_flow_intact_flow_lowest_resolution_t(m, conn)
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_connection_flow_intact_flow_indices(m, conn, t)),
        )
    )
end

"""
    constraint_connection_flow_intact_flow_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_flow_intact_flow` constraint.

Uses stochastic path indices of the `connection_flow` and `connection_intact_flow` variables. Only the lowest
resolution time slices are included, as the `:connection_flow_capacity` is used to constrain the "average power" of the
`connection` instead of "instantaneous power". Keyword arguments can be used to filter the resulting
"""
function constraint_connection_flow_intact_flow_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_flow_intact_flow_indices(m))
end

"""
    _candidate_connections(conn)

An iterator over all candidate connections that can impact the flow on the given connection.
"""
function _candidate_connections(conn)
    (
        candidate_conn for candidate_conn in connection(is_candidate=true, has_ptdf=true)
            if candidate_conn !== conn && lodf(connection1=candidate_conn, connection2=conn) !== nothing
    )
end

function _constraint_connection_flow_intact_flow_lowest_resolution_t(m, conn)
    t_lowest_resolution(
        ind.t
        for conn_k in Iterators.flatten(((conn,), _candidate_connections(conn)))
        for ind in connection_flow_indices(m; connection=conn_k, last(connection__from_node(connection=conn_k))...)
    )
end

"""
    _constraint_connection_flow_intact_flow_indices(connection, node, direction1, node2, direction2, t)

Gather the indices of the relevant `connection_flow` variables.
"""
function _constraint_connection_flow_intact_flow_indices(m, conn, t)
    (
        ind
        for conn_k in Iterators.flatten(((conn,), _candidate_connections(conn))) for ind in connection_flow_indices(
            m;
            connection=conn_k,
            last(connection__from_node(connection=conn_k))...,
            t=t_in_t(m; t_long=t),
        )
    )
end
