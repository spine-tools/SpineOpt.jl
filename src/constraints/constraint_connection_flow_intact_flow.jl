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

Enforces the relationship between the `intact_flow` (flow with all investments assumed in force) and the `connection_flow`

`intact_flow` is the flow on all lines with all investments assumed in place. This constraint ensures that the `connection_flow`
is the `intact_flow` plus additional contributions from all investments not invested in.

"""
function add_constraint_connection_flow_intact_flow!(m::Model)
    @fetch connection_flow, connection_intact_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:connection_flow_intact_flow] = Dict(
        (connection=conn, node=ng, stochastic_path=s, t=t) => @constraint(
            m,
            +expr_sum(
                + connection_flow[conn, n, direction(:from_node), s, t] * duration(t)
                - connection_flow[conn, n, direction(:to_node), s, t] * duration(t)
                - connection_intact_flow[conn, n, direction(:from_node), s, t] * duration(t)
                + connection_intact_flow[conn, n, direction(:to_node), s, t] * duration(t)                
                #for s in s
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
            +expr_sum( 
                lodf(connection1=candidate_connection, connection2=conn) *
                ( + connection_intact_flow[candidate_connection, n, direction(:from_node), s, t] * duration(t)
                  - connection_intact_flow[candidate_connection, n, direction(:to_node), s, t] * duration(t)
                  - connection_flow[candidate_connection, n, direction(:from_node), s, t] * duration(t)
                  + connection_flow[candidate_connection, n, direction(:to_node), s, t] * duration(t) )
                for candidate_connection in connection(is_candidate=true, has_ptdf=true) 
                    if candidate_connection !== conn && ! (lodf(connection1=candidate_connection, connection2 = conn) == nothing)
                for n in last(connection__from_node(connection=candidate_connection))
                for
                (candidate_connection, n, d, s, t) in connection_flow_indices(
                    m;    
                    connection=candidate_connection,
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

"""
    constraint_connection_flow_intact_flow_indices(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_flow_intact_flow` constraint.

Uses stochastic path indices of the `connection_flow` and `connection_intact_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting 
"""

function constraint_connection_flow_intact_flow_indices(
    m::Model;
    connection=connection(connection_monitored=true, has_ptdf=true),
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    unique(
        (connection=conn, node=n_to, stochastic_path=path, t=t)        
        for conn in connection if connection_monitored(connection=conn) && has_ptdf(connection=conn) && !(conn in indices(candidate_connections))
        for candidate_connection in indices(candidate_connections)  if candidate_connection != conn && has_ptdf(connection=conn) 
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn, node=node; _compact=false), 1)
        for (conn_k, n_to_k, d_to_k) in Iterators.drop(connection__from_node(connection=candidate_connection; _compact=false), 1)
        for t in t_lowest_resolution(
            vcat(
                [ind.t for ind in connection_flow_indices(m; connection=conn, node=n_to, direction=d_to)],
                [ind.t for ind in connection_flow_indices(m; connection=conn_k, node=n_to_k, direction=d_to_k)]
            )
        )
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_connection_flow_intact_flow_indices(m, conn, n_to, d_to, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end


"""
    _constraint_connection_flow_intact_flow_indices(connection, node, direction1, node2, direction2, t)

Gather the indices of the relevant `connection_flow` variables.
"""
function _constraint_connection_flow_intact_flow_indices(m, conn, node, direction, t)    
    Iterators.flatten((
        connection_flow_indices(
            m;
            connection=conn,
            last(connection__from_node(connection=conn))...,
            t=t_in_t(m; t_long=t),
        ),  # Monitored connection
        (connection_flow_indices(
            m;
            connection=anything,
            last(connection__from_node(connection=conn_k))...,
            t=t_in_t(m; t_long=t),
        ) for conn_k in connection(cadidate_connection=true, has_ptdf=true) if conn_k != conn) ,  # Investment connections 
    ))
end
