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
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
"""
function constraint_nodal_balance(m::Model, flow, trans)
	@butcher for (n, tblock) in node__temporal_block(), t in time_slice(temporal_block=tblock)
        @constraint(
            m,
			0
            ==
            # Demand for the commodity
			- (demand(node=n)(t=t) != nothing && demand(node=n)(t=t))
            # Output of units into this node, and their input from this node
            + reduce(
                +,
                flow[c, n, u, :out, t2]
                for (c, u, trashblock) in commodity__node__unit__direction__temporal_block(node=n, direction=:out)
                    for t2 in t_in_t(t_long=t)
                        if haskey(flow, (c, n, u, :out, t2));
                init=0
            )
            - reduce(
                +,
                flow[c, n, u, :in, t2]
                for (c, u, trashblock) in commodity__node__unit__direction__temporal_block(node=n, direction=:in)
                    for t2 in t_in_t(t_long=t)
                        if haskey(flow, (c, n, u, :in, t2));
                init=0
            )
            # Transfer of commodities between nodes
            + reduce(
                +,
                trans[c, n, conn, :out, t2]
                for (c, conn, trashblock) in commodity__node__connection__direction__temporal_block(node=n, direction=:out)
                    for t2 in t_in_t(t_long=t)
                        if haskey(trans, (c, n, conn, :out, t2));
                init=0
            )
            - reduce(
                +,
                trans[c, n, conn, :in, t2]
                for (c, conn, trashblock) in commodity__node__connection__direction__temporal_block(node=n, direction=:in)
                    for t2 in t_in_t(t_long=t)
                        if haskey(trans, (c, n, conn, :in, t2));
                init=0
            )
        )
    end
end
#=
# new proposed version (not currently working because we don't yet have the required functionality)
#@ TO DO: exogeneous supply parameter to be added
function constraint_nodal_balance(m::Model, flow, trans, time_slice,timesliceblocks)
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
	                flow[c, n, u, :out, tprime] min(time_slice_duration(t), time_slice_duration(t_prime)) # @Manuel, Maren: important that we get this to work!
	                for (c, u, tprime) in commodity__node__unit__direction__time_slice(node=n, direction=:out) # @Maren, @Manuel: Important that we get this to work nicely!
						if t_prime in t_overlaps_t(t)
	                )
	            - reduce(+,
	                flow[c, n, u, :in, t]
	                for (c, u, t_prime) in commodity__node__unit__direction__time_slice(node=n, direction=:in)
						if t_prime in t_overlaps_t(t)
	                )
	            # @Maren: transfers should be adjusted in a similar fashion
	            + reduce(+,
	                trans[c, n, conn, :out, t]
	                for (c, conn) in commodity__node__connection__direction(node=n, direction=:out)
						if haskey(trans,(c,n,conn,:out,t));
	                    init=0
	                )
	            - reduce(+,
	                trans[c, n, conn, :in, t]
	                for (c, conn) in commodity__node__connection__direction(node=n, direction=:in)
						if haskey(trans,(c,n,conn,:in,t));
	                    init=0
	                )
	        )
    end
end
=#
