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
    constraint_nodal_balance(m::Model)

Enforce balance of all commodity flows from and to a node.
"""
@catch_undef function constraint_nodal_balance(m::Model)
	@fetch flow, trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:nodal_balance] = Dict()
	for (n, tblock) in node__temporal_block()
        for t in time_slice(temporal_block=tblock)
            constr_dict[n, t] = @constraint(
                m,
	   			0
                ==
                # Demand for the commodity
                - (demand(node=n, t=t) != nothing && demand(node=n, t=t) * duration(t))
                # Commodity flows from units
                + reduce(
                    +,
                    flow[u, n, c, d, t1] * duration(t1)
                    for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
                # Commodity flows to units
                - reduce(
                    +,
                    flow[u, n, c, d, t1] * duration(t1)
                    for (u, n, c, d, t1) in flow_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
                )
                # Commodity transfers from connections
                + reduce(
                    +,
                    trans[conn, n, c, d, t1] * duration(t1)
                    for (conn, n, c,d,t1) in trans_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
                # Commodity transfers to connections
                - reduce(
                    +,
                    trans[conn, n, c, d, t1] * duration(t1)
                    for (conn, n, c,d,t1) in trans_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
                )
            )
        end
    end
end
#=
@Kris: is this still needed?
# new proposed version (not currently working because we don't yet have the required functionality)
#@ TO DO: exogeneous supply parameter to be added
@catch_undef function constraint_nodal_balance(m::Model, flow, trans, time_slice,timesliceblocks)
	for (n,tblock) in node__temporal_block()
		for t in keys(timesliceblocks[tblock])
	        @constraint(
	            m,
				0
	            ==
	            # Demand for the commodity
	            - sum(
					demand_t(node=n, time_slice=t) time_slice_duration(t) #@Maren, Manuel: how handled if parameter not defined for that tuple?
				)
				# Output of units into this node, and their input from this node
	            + reduce(+,
	                flow[c, n, u, :to_node, tprime] min(time_slice_duration(t), time_slice_duration(t_prime)) # @Manuel, Maren: important that we get this to work!
	                for (c, u, tprime) in commodity__node__unit__direction__time_slice(node=n, direction=:to_node) # @Maren, @Manuel: Important that we get this to work nicely!
						if t_prime in t_overlaps_t(t)
	                )
	            - reduce(+,
	                flow[c, n, u, :from_node, t]
	                for (c, u, t_prime) in commodity__node__unit__direction__time_slice(node=n, direction=:from_node)
						if t_prime in t_overlaps_t(t)
	                )
	            # @Maren: transfers should be adjusted in a similar fashion
	            + reduce(+,
	                trans[c, n, conn, :to_node, t]
	                for (c, conn) in commodity__node__connection__direction(node=n, direction=:to_node)
						if haskey(trans,(c,n,conn,:to_node,t));
	                    init=0
	                )
	            - reduce(+,
	                trans[c, n, conn, :from_node, t]
	                for (c, conn) in commodity__node__connection__direction(node=n, direction=:from_node)
						if haskey(trans,(c,n,conn,:from_node,t));
	                    init=0
	                )
	        )
    end
end
=#
