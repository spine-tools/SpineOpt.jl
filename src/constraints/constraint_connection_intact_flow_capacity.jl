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
    add_constraint_connection_intact_flow_capacity!(m::Model)

Limit the maximum in/out `connection_intact_flow` of a `connection` for all `connection_intact_flow_capacity` indices.

Check if `connection_conv_cap_to_flow` is defined. The `connection_capacity` parameter is used to constrain the
"average power" (e.g. MWh/h) instead of "instantaneous power" (e.g. MW) of the `connection`.
For most applications, there isn't any difference between the two. However, for situations where the same `connection`
handles `connection_intact_flows` to multiple `nodes` with different temporal resolutions, the constraint is only generated
for the lowest resolution, and only the average of the higher resolution `connection_intact_flow` is constrained.
If instantaneous power needs to be constrained as well, defining the `connection_capacity` separately for each
`connection_intact_flow` can be used to achieve this.
"""
function add_constraint_connection_intact_flow_capacity!(m::Model)
    @fetch connection_intact_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:connection_intact_flow_capacity] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                connection_intact_flow[conn, n, d, s, t] * duration(t)
                for (conn, n, d, s, t) in connection_intact_flow_indices(
                    m; connection=conn, direction=d, node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                );
                init=0
            )
            - connection_capacity[
                (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
            ]
            * connection_availability_factor[
                (connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)
            ]
            * connection_conv_cap_to_flow[
                (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
            ]
            * duration(t)
            <=
            + expr_sum(
                connection_intact_flow[conn, n, d_reverse, s, t] * duration(t)
                for (conn, n, d_reverse, s, t) in connection_intact_flow_indices(
                    m; connection=conn, node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                )
                if d_reverse != d && !is_reserve_node(node=n);
                init=0
            )
        )
        for (conn, ng, d, s, t) in constraint_connection_intact_flow_capacity_indices(m)
    )
end

"""
    constraint_connection_intact_flow_capacity_indices(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_intact_flow_capacity` constraint.

Uses stochastic path indices of the `connection_intact_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_intact_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting 
"""
function constraint_connection_intact_flow_capacity_indices(
    m::Model; connection=anything, node=anything, direction=anything, stochastic_path=anything, t=anything
)
    unique(
        (connection=c, node=ng, direction=d, stochastic_path=path, t=t)
        for (c, ng, d) in indices(connection_capacity; connection=connection, node=node, direction=direction)
        if has_ptdf(connection=c)
        for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=members(ng)), t=t))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario for ind in connection_intact_flow_indices(m; connection=c, node=ng, direction=d, t=t)
            )
        )
        if path == stochastic_path || path in stochastic_path
    )
end
