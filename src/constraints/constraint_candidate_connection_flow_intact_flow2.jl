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
    add_constraint_candidate_connection_flow_intact_flow!(m::Model)

Limit the maximum in/out `connection_flow` of a `connection` for all `connection_flow_capacity` indices.

Check if `connection_conv_cap_to_flow` is defined. The `connection_capacity` parameter is used to constrain the
"average power" (e.g. MWh/h) instead of "instantaneous power" (e.g. MW) of the `connection`.
For most applications, there isn't any difference between the two. However, for situations where the same `connection`
handles `connection_flows` to multiple `nodes` with different temporal resolutions, the constraint is only generated
for the lowest resolution, and only the average of the higher resolution `connection_flow` is constrained.
If instantaneous power needs to be constrained as well, defining the `connection_capacity` separately for each
`connection_flow` can be used to achieve this.
"""
function add_constraint_candidate_connection_flow_intact_flow2!(m::Model)
    @fetch connection_flow, connection_intact_flow, connections_invested_available = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:candidate_connection_flow_intact_flow] = Dict(
        (connection=conn, node=n, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            +expr_sum(
                connection_flow[conn, n, d, s, t] * duration(t)
                for
                (conn, n, d, s, t) in connection_flow_indices(
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
                for
                (conn, n, d, s, t) in connection_intact_flow_indices(
                    m;
                    connection=conn,
                    direction=d,
                    node=n,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )    
            - ( candidate_connections(connection=conn) - expr_sum(
                    connections_invested_available[conn, s, t1]
                    for
                    (conn, s, t1) in
                    connections_invested_available_indices(m; connection=conn, stochastic_scenario=s, t=t_in_t(m; t_short=t));
                    init=0,
                ) 
            ) * 100000
            
        )        
        for (conn, n, d, s, t) in constraint_candidate_connection_flow_intact_flow2_indices(m)
    )
end

"""
    constraint_connection_intact_flow_capacity_indices(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_intact_flow_capacity` constraint.

Uses stochastic path indices of the `connection_intact_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_intact_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting 
"""
function constraint_candidate_connection_flow_intact_flow2_indices(
    m::Model;
    connection=connection(is_candidate=true, has_ptdf=true),
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything
)
    unique(
        (connection=conn, node=n, direction=d, stochastic_path=path, t=t)
        for (conn, n, d, s, t) in connection_flow_indices(m; connection=connection, node=node, direction=direction)            
        for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=n), t=t))
        for path in active_stochastic_paths(unique(
                    ind.stochastic_scenario for ind in _constraint_candidate_connection_flow_intact_flow2_indices(m, conn, n, d, t)            
            )) if path == stochastic_path || path in stochastic_path        
    )
end


"""
    _constraint_connection_flow_capacity_indices(connection, node, direction1, node2, direction2, t)

Gather the indices of the relevant `unit_flow` and `units_on` variables.
"""
function _constraint_candidate_connection_flow_intact_flow2_indices(m, connection, node, direction, t)
    (m, connection, node, direction, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=connection, node=node, direction=direction, t=t),        
        connections_invested_available_indices(m; connection=connection, t=t_in_t(m; t_short=t))
    ))
end