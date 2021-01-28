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
    add_constraint_connection_flow_capacity!(m::Model)

Limit the maximum in/out `connection_flow` of a `connection` for all `connection_flow_capacity` indices.

Check if `connection_conv_cap_to_flow` is defined. The `connection_capacity` parameter is used to constrain the
"average power" (e.g. MWh/h) instead of "instantaneous power" (e.g. MW) of the `connection`.
For most applications, there isn't any difference between the two. However, for situations where the same `connection`
handles `connection_flows` to multiple `nodes` with different temporal resolutions, the constraint is only generated
for the lowest resolution, and only the average of the higher resolution `connection_flow` is constrained.
If instantaneous power needs to be constrained as well, defining the `connection_capacity` separately for each
`connection_flow` can be used to achieve this.
"""
function add_constraint_connection_flow_intact_flow!(m::Model)
    @fetch connection_flow, connection_intact_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:constraint_connection_flow_intact_flow] = Dict(
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
                ( + connection_intact_flow[candidate_connection, n, direction(:to_node), s, t] * duration(t)
                  - connection_intact_flow[candidate_connection, n, direction(:from_node), s, t] * duration(t)
                  - connection_flow[candidate_connection, n, direction(:to_node), s, t] * duration(t)
                  + connection_flow[candidate_connection, n, direction(:from_node), s, t] * duration(t) )
                for candidate_connection in connection(is_candidate=true, has_ptdf=true) 
                    if candidate_connection !== conn && ! (lodf(connection1=candidate_connection, connection2 = conn) == nothing)
                for n in last(connection__from_node(connection=candidate_connection))
                for
                (candidate_connection, n, d, s, t) in connection_flow_indices(
                    m;    
                    connection=candidate_connection,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )*duration(t) 
        ) for (conn, ng, s, t) in constraint_connection_flow_intact_flow_indices(m)
    )
end

"""
    constraint_connection_flow_capacity_indices(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_flow_capacity` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the lowest resolution time slices are included,
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
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn, node=node; _compact=false), 1)                            
        for t in t_lowest_resolution(
            vcat(
                [ind.t
                for ind in connection_flow_indices(m; connection=conn, node=n_to, direction=d_to)],
                [ind.t for candidate_connection in indices(candidate_connections)  if candidate_connection != conn && has_ptdf(connection=conn) 
                for ind in connection_flow_indices(m; connection=candidate_connection, direction=direction(:to_node))],
            )
        )
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_connection_intact_flow_ptdf_indices(m, conn, n_to, d_to, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end


"""
    _constraint_connection_flow_capacity_indices(connection, node, direction1, node2, direction2, t)

Gather the indices of the relevant `unit_flow` and `units_on` variables.
"""
function _constraint_connection_flow_intact_flow_indices(m, connection, node, direction, t)
    (m, connection, node, direction, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=connection, node=node, direction=direction, t=t),
        (
            connection_flow_indices(m; connection=canidate_connection, node=node, direction=direction, t=t)
            for candidate_connection in connection(is_candidate=true) if canididate_connection !== connection
        )
    ))
end
