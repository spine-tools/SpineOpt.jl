# TODO: this is a user_custom constraint
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
    add_constraint_limit_export(m::Model)

Limit the max export from one node group.
TODO: at the moment this constraint only limits the export over one connection to be lower than the local production from a node gorup ng.
This needs to be handled more generically: limit export could be defined on
(n, ug,conng1,conng2), where
ug: unit group of local productions at node n
conng1: conn group of local import to node n
conng2: conn group of local export from node n
sum(unit_flow in ug) + sum(connection_flow in conng1) >= sum(connection_flow in conng2)
"""

##TODO keep this one as custom constraint
function add_constraint_limit_export!(m::Model)
	@fetch unit_flow, connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:limit_export] = Dict()
	for ng in indices(limit_export)
		for (conn, n, d, s, t) in connection_flow_indices(node=ng, direction = direction(:to_node))
	            cons[n, conn, s, t] = @constraint(
	                m,
	                + reduce(
	                    +,
	                    unit_flow[u, n, d, s, t1] * duration(t1)
	                    for (u, n, d, s, t1) in unit_flow_indices(node=ng, t=t_in_t(t_long=t), direction=d);
	                    init=0
	                )
	                >=
	                + reduce(
	                    +,
	                    connection_flow[conn, n, d, s, t] * duration(t)
	                    for (conn, n, d, s, t) in connection_flow_indices(connection=conn, direction=d, t=t)
								if !in(n,expand_node_group(ng));
	                    init=0
	                )
	            )
        	end
		end
    end
end
