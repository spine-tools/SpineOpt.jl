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
    add_constraint_connection_flow_ptdf!(m::Model)

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs.
"""
function add_constraint_connection_flow_ptdf!(m::Model)
    @fetch connection_flow, node_injection = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:connection_flow_ptdf] = Dict(
        (connection=conn, node=n_to, stochastic_path=s, t=t) => @constraint(
            m,
            +expr_sum(
                +get(connection_flow, (conn, n_to, direction(:to_node), s, t), 0) -
                get(connection_flow, (conn, n_to, direction(:from_node), s, t), 0) for s in s;
                init=0,
            ) ==
            +expr_sum(
                ptdf(connection=conn, node=n) * node_injection[n, s, t] for (conn, n) in indices(ptdf; connection=conn)
                for
                (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s, t=t) if
                !isapprox(ptdf(connection=conn, node=n), 0; atol=node_ptdf_threshold(node=n));
                init=0,
            ) # this is the increase in flow on the line for all candidate connections that are not invested in
            +expr_sum(
                +get(connection_flow, (candidate_connection, n_to, direction(:to_node), s, t), 0) -
                get(connection_flow, (candidate_connection, n_to, direction(:from_node), s, t), 0)
                for candidate_connection in indices(candidate_connections) if candidate_connection != conn
                for n_to in connection__to_node(connection=candidate_connection)
                for s in s;
                init=0,
            ) * (1 - connections_invested_available_mp[(connection=candidate_connection, stochastic_scenario=s, analysis_time=t0, t=t))])
              * lodf(connection1=candidate_connection, connection2=conn)
        ) for (conn, n_to, s, t) in constraint_connection_flow_ptdf_indices(m)
    )
end

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

"""
    constraint_connection_flow_ptdf_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_flow_lodf` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`connection_flow` and `node_injection` variables? Keyword arguments can be used for filtering the resulting Array.
"""
function constraint_connection_flow_ptdf_indices(
    m::Model;
    connection=connection(connection_monitored=true, has_ptdf=true),
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    unique(
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection if connection_monitored(connection=conn) && has_ptdf(connection=conn)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn, node=node; _compact=false), 1)
        for (n_to, t) in node_time_indices(m; node=n_to, t=t)
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_connection_flow_ptdf_indices(m, conn, n_to, d_to, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_connection_flow_ptdf_indices(connection, node_to, direction_to, t)

Gather the indices of the `connection_flow` and the `node_injection` variables appearing in
`add_constraint_connection_flow_ptdf!`.
"""
function _constraint_connection_flow_ptdf_indices(m, connection, node_to, direction_to, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=connection, node=node_to, direction=direction_to, t=t),  # `n_to`
        (
            ind for (conn, n_inj) in indices(ptdf; connection=connection)
            for ind in node_stochastic_time_indices(m; node=n_inj, t=t)
        ),  # `n_inj`
    ))
end


"""
    _constraint_connection_flow_ptdf_lowest_resolution_t(m::Model, conn::Object)

Find the lowest resolution `t`s between the `connection_flow` variables of the `conn` connection and
all candidate connections candidate_conn.
"""
function _constraint_connection_flow_ptdf_lowest_resolution_t(m, conn, t)
    t_lowest_resolution(
        vcat(
            [ind.t for ind in connection_flow_indices(m; connection=conn, last(connection__from_node(connection=conn))..., t=t)],
            [ind.t for candidate_connection in indices(candidate_connections) if candidate_connection != conn
            for ind in connection_flow_indices(m; connection=candidate_connections, last(connection__from_node(connection=conn))..., t=t)],
        )
    )
end

"""
    _constraint_connection_flow_ptdf_indices(conn, t)

Gather the indices of the `connection_flow` variable for the connection `conn` and all investment
candidate connections `candidate_connection` on time slice `t`.
"""
function _constraint_connection_flow_ptdf_indices(m, conn, t)
    Iterators.flatten((
        connection_flow_indices(
            m;
            connection=conn,
            last(connection__from_node(connection=conn))...,
            t=t_in_t(m; t_long=t),
        ),
        [connection_flow_indices(
            m;
            connection=candidate_connection,
            last(connection__from_node(connection=candidate_connection))...,
            t=t_in_t(m; t_long=t),
            ) for candidate_connection in indices(candidate_connections) if candidate_connections != conn
        ],  # Excess flow due to non-investment in candidate connection
    ))
end
