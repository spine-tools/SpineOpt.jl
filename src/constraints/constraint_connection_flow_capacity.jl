#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
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
Check if `connection_conv_cap_to_flow` is defined.
"""
function add_constraint_connection_flow_capacity!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:connection_flow_capacity] = Dict()
    @warn "How to incorporate temporal correctly? Stoachstics not straight forward"
    @warn "Add reservE_node to data"
    for (conn, n, d) in indices(connection_capacity)
        for t in time_slice()
            cons[conn, n, d,t] = @constraint(
                m,
                + expr_sum(
                    connection_flow[conn, n, d, s, t] #TODO: why did we get of duration here?
                        for (conn, n, d, s, t) in connection_flow_indices(connection=conn, direction=d, node=n, t=t);
                    init=0
                )
                <=
                + connection_capacity[(connection=conn, node=n, direction=d, t=t)] # TODO: Stochastic parameters
                * connection_availability_factor[(connection=conn, t=t)]
                * connection_conv_cap_to_flow[(connection=conn, node=n, direction=d, t=t)]
                + expr_sum(
                    connection_flow[conn, n, d_reverse, s, t] #TODO: why did we get of duration here?
                        for (conn, n, d_reverse, s, t) in connection_flow_indices(connection=conn, node=n, t=t)
                            if d_reverse != d && is_reserve_node(node=n) == :is_reserve_node_false;
                    init=0
                )
            )
        end
    end
end
