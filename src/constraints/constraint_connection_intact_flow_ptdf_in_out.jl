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
    add_constraint_connection_intact_flow_ptdf_in_out!(m::Model)

For connection investments with PTDFs enabled, constrain that the flow into a connection must equal the flow out
"""
function add_constraint_connection_intact_flow_ptdf_in_out!(m::Model)
    @fetch connection_intact_flow, node_injection = m.ext[:variables]
    m.ext[:constraints][:connection_intact_flow_ptdf_in_out] = Dict(
        (connection=conn, node_to=n_to, node_from=n_from, stochastic_path=s, t=t) => @constraint(
            m,
            +expr_sum(
                +get(connection_intact_flow, (conn, n_to, direction(:to_node), s, t), 0) -
                get(connection_intact_flow, (conn, n_to, direction(:from_node), s, t), 0) for s in s;
                init=0,
            ) == 
            +expr_sum(
                -get(connection_intact_flow, (conn, n_from, direction(:to_node), s, t), 0) +
                get(connection_intact_flow, (conn, n_from, direction(:from_node), s, t), 0) for s in s;
                init=0,
            )
        ) for (conn, n_to, n_from, s, t) in constraint_connection_intact_flow_ptdf_in_out_indices(m)
    )
end

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

"""
    constraint_connection_intact_flow_ptdf_in_out_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_intact_flow_ptdf_in_out` constraint.

Uses stochastic path indices due to potentially different stochastic structures between the 
`connection_intact_flow` variables at node_from and node_to. Keyword arguments can be used for filtering the resulting Array.
"""
function constraint_connection_intact_flow_ptdf_in_out_indices(
    m::Model;
    connection=connection(connection_monitored=true, has_ptdf=true),
    node_to=anything,
    node_from=anything,
    stochastic_path=anything,
    t=anything,
)
    unique(
        (connection=conn, node_to=n_to, node_from=n_from, stochastic_path=path, t=t)
        for conn in connection if connection_monitored(connection=conn) && has_ptdf(connection=conn)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn, node=node_to; _compact=false), 1)
        for (conn, n_from, d_from) in Iterators.drop(connection__to_node(connection=conn, node=node_from; _compact=false), 1)
        for (n_to, t) in node_time_indices(m; node=n_to, t=t)        
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_connection_intact_flow_ptdf_in_out_indices(m, conn, n_to, n_from, d_to, d_from, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_connection_intact_flow_ptdf_in_out_indices(connection, node_to, direction_to, t)

Gather the indices of the `connection_intact_flow` variables appearing in `add_constraint_connection_intact_flow_ptdf_in_out!`.
"""
function _constraint_connection_intact_flow_ptdf_in_out_indices(m, connection, node_to, direction_to, node_from, direction_from, t)
    Iterators.flatten((        
        connection_intact_flow_indices(m; connection=connection, node=node_to, direction=direction_to, t=t),  # `n_to`
        (
            ind for (conn, n_inj) in indices(ptdf; connection=connection)
            for ind in node_stochastic_time_indices(m; node=n_inj, t=t)
        ),
        connection_intact_flow_indices(m; connection=connection, node=node_from, direction=direction_from, t=t),  # `n_from`
        (
            ind for (conn, n_inj) in indices(ptdf; connection=connection)
            for ind in node_stochastic_time_indices(m; node=n_inj, t=t)
        ),
        # `n_inj`
    ))
end
