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
    add_constraint_candidate_connection_flow_lb!(m::Model)

For connection investments with PTDF flow enabled, this constrains the flow on the candidate_connection
to be equal to connection_intact_flow if connections_invested_available is equal to 1 and is rendered
in active otherwise where contraint connection_flow_capacity will constraint the flow to zero.
"""
function add_constraint_candidate_connection_flow_lb!(m::Model)
    @fetch connection_flow, connection_intact_flow, connections_invested_available = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:candidate_connection_flow_lb] = Dict(
        (connection=conn, node=n, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                connection_flow[conn, n, d, s, t] * duration(t) for (conn, n, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    direction=d,
                    node=n,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            >=
            + expr_sum(
                connection_intact_flow[conn, n, d, s, t] * duration(t)
                for (conn, n, d, s, t) in connection_intact_flow_indices(
                    m;
                    connection=conn,
                    direction=d,
                    node=n,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            - (
                candidate_connections(connection=conn) - expr_sum(
                    connections_invested_available[conn, s, t1]
                    for (conn, s, t1) in connections_invested_available_indices(
                        m;
                        connection=conn,
                        stochastic_scenario=s,
                        t=t_in_t(m; t_short=t),
                    );
                    init=0,
                )
            )
            * ((
                connection_capacity(
                    connection=conn,
                    node=n,
                    direction=d,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t,
                ) == nothing
            ) ? 1000000 :
               connection_capacity(
                connection=conn,
                node=n,
                direction=d,
                stochastic_scenario=s,
                analysis_time=t0,
                t=t,
            ))
            * duration(t)
        ) for (conn, n, d, s, t) in constraint_candidate_connection_flow_lb_indices(m)
    )
end

function constraint_candidate_connection_flow_lb_indices(m::Model)
    unique(
        (connection=conn, node=n, direction=d, stochastic_path=path, t=t)
        for (conn, n, d, s, t) in connection_flow_indices(m; connection=connection(is_candidate=true, has_ptdf=true))
        for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=n)))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario for ind in _constraint_candidate_connection_flow_lb_indices(m, conn, n, d, t)
            ),
        )
    )
end

"""
    constraint_candidate_connection_flow_lb_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_intact_flow_lb` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting indices
"""
function constraint_candidate_connection_flow_lb_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_candidate_connection_flow_lb_indices(m))
end

"""
    _constraint_connection_flow_lb_indices(m; connection, node, direction, t)

Gather the indices of the relevant `connection_flow` and `connections_invested_available` variables.
"""
function _constraint_candidate_connection_flow_lb_indices(m, connection, node, direction, t)
    (m, connection, node, direction, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=connection, node=node, direction=direction, t=t),
        connections_invested_available_indices(m; connection=connection, t=t_in_t(m; t_short=t)),
    ))
end
