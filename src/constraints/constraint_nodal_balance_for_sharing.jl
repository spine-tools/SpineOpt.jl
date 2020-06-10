# Done: check if working
# #############################################################################
# # Copyright (C) 2017 - 2018  Spine Project
# #
# # This file is part of Spine Model.
# #
# # Spine Model is free software: you can redistribute it and/or modify
# # it under the terms of the GNU Lesser General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.
# #
# # Spine Model is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# # GNU Lesser General Public License for more details.
# #
# # You should have received a copy of the GNU Lesser General Public License
# # along with this program.  If not, see <http://www.gnu.org/licenses/>.
# #############################################################################
#
# """
#     constraint_nodal_balance_for_sharing(m::Model)
#
# Enforce balance of all commodity flows from and to a node.
# """
# function add_constraint_nodal_balance_for_sharing!(m::Model)
# 	@fetch flow, trans = m.ext[:variables]
#     cons = m.ext[:constraints][:nodal_balance_for_sharing] = Dict()
# 	for n in indices(reserve_demand)
# 		for tblock in node__temporal_block(node=n)
#         	for t in time_slice(temporal_block=tblock)
#             cons[n, t] = @constraint(
#                 m,
#                 # Demand for the commodity
#                 - reserve_demand(node=n, t=t) * duration(t)
#                 # Commodity flows from units
#                 + reduce(
#                     +,
#                     flow[u, n, c, d, t1] * duration(t1)
#                     for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t), direction=direction(:to_node));
#                     init=0
#                 )
#                 # Commodity flows to units
#                 - reduce(
#                     +,
#                     flow[u, n, c, d, t1] * duration(t1)
#                     for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t), direction=direction(:from_node));
#                     init=0
#                 )
#                 # Commodity transfers from connections
#                 + reduce(
#                     +,
#                     trans[conn, n1, c, d, t1] * duration(t1)
#                     for (conn, n1, c, d, t1) in trans_indices(node=n, t=t_in_t(t_long=t), direction=direction(:to_node))
# 						for n2 in connection__node__node(connection=conn,node1=n1)
# 							if !in(n2,expand_node_group(n));
#                     init=0
#                 )
#                 # Commodity transfers to connections
#                 - reduce(
#                     +,
#                     trans[conn, n1, c, d, t1] * duration(t1)
#                     for (conn, n1, c, d, t1) in trans_indices(node=n, t=t_in_t(t_long=t), direction=direction(:from_node))
# 						for n2 in connection__node__node(connection=conn,node1=n1)
# 							if !in(n2,expand_node_group(n));
#                     init=0
# 				)
# 				in eval(Meta.parse(eval(:("MOI.$(rel_operator_demand(node=$n))"))))
#             )
#         end
# 	end
#     end
# end
#
#
# function update_constraint_nodal_balance_for_sharing!(m::Model)
#     cons = m.ext[:constraints][:nodal_balance_for_sharing]
# 	for n in indices(reserve_demand)
# 		for tblock in node__temporal_block(node=n)
#         	for t in time_slice(temporal_block=tblock)
# 	            set_normalized_rhs(cons[n, t], reserve_demand(node=n, t=t) * duration(t))
# 	        end
# 		end
#     end
# end
