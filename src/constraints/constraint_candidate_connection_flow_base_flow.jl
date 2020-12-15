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
    add_constraint_candidate_connection_flow_capacity!(m::Model)

Limit the maximum in/out `connection_flow` of a `connection` for all `connection_flow_capacity` indices.

Check if `connection_conv_cap_to_flow` is defined. The `connection_capacity` parameter is used to constrain the
"average power" (e.g. MWh/h) instead of "instantaneous power" (e.g. MW) of the `connection`.
For most applications, there isn't any difference between the two. However, for situations where the same `connection`
handles `connection_flows` to multiple `nodes` with different temporal resolutions, the constraint is only generated
for the lowest resolution, and only the average of the higher resolution `connection_flow` is constrained.
If instantaneous power needs to be constrained as well, defining the `connection_capacity` separately for each
`connection_flow` can be used to achieve this.
"""
function add_constraint_candidate_connection_flow_base_flow!(m::Model)
    @fetch candidate_connection_flow, connection_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:candidate_connection_flow_capacity] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + candidate_connection_flow[conn, n, d, s, t]
            <=
            + connection_flow[conn, n, d, s, t]
            
        )
        for (conn, ng, d, s, t) in candidate_connection_flow_indices(m)
    )
end
