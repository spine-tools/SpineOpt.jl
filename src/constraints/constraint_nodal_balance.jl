"""
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
"""
function constraint_nodal_balance(m::Model, flow, trans, timeslicemap,timesliceblocks)
	for (n,tblock) in node__temporal_block(), t in keys(timeslicemap)
        all([
			demand_t(node=n, temporal_block=tblock) !=0,
			in(t,keys(timesliceblocks[tblock]))
        ]) || continue
        @constraint(
            m,
			0
            ==
            # Demand for the commodity
            - demand_t(node=n, temporal_block=tblock)
            # Output of units into this node, and their input from this node
            + reduce(+,
                flow[c, n, u, :out, t]
                for (c, u) in commodity__node__unit__direction(node=n, direction=:out)
					if haskey(flow,(c,n,u,:out,t));
                    init=0
                )
            - reduce(+,
                flow[c, n, u, :in, t]
                for (c, u) in commodity__node__unit__direction__temporal_block(node=n, direction=:in)
					if haskey(flow,(c,n,u,:in,t));
                    init=0
                )
            # Transfer of commodities between nodes
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
