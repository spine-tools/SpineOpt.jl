"""
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
"""
function constraint_nodal_balance(m::Model, flow, trans, timeslicemap, t_in_t)
	for (n,tblock) in node__temporal_block(), t in timeslicemap(temporal_block=tblock)
        # all([
		# 	demand_t(node=n, temporal_block=tblock) !=0
        # ]) || continue
        @constraint(
            m,
			0
            ==
            # Demand for the commodity
			- ( demand_t(node__temporal_block=(n,tblock)) != nothing &&
				demand_t(node__temporal_block=(n,tblock))
				)
            # Output of units into this node, and their input from this node
            + reduce(+,
                flow[c, n, u, :out, t2]
                for (c, u) in commodity__node__unit__direction(node=n, direction=:out)
					for t2 in t_in_t(t_above=t)
					if haskey(flow,(c,n,u,:out,t2));
                    init=0
                )
            - reduce(+,
                flow[c, n, u, :in, t2]
                for (c, u) in commodity__node__unit__direction__temporal_block(node=n, direction=:in)
					for t2 in t_in_t(t_above=t)
					if haskey(flow,(c,n,u,:in,t2));
                    init=0
                )
            # Transfer of commodities between nodes
            + reduce(+,
                trans[c, n, conn, :out, t]
                for (c, conn) in commodity__node__connection__direction(node=n, direction=:out)
					for t2 in t_in_t(t_above=t)
					if haskey(trans,(c,n,conn,:out,t2));
                    init=0
                )
            - reduce(+,
                trans[c, n, conn, :in, t]
                for (c, conn) in commodity__node__connection__direction(node=n, direction=:in)
					for t2 in t_in_t(t_above=t)
					if haskey(trans,(c,n,conn,:in,t2));
                    init=0
                )
        )
    end
end
