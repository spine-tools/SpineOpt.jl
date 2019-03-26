"""
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
"""
function constraint_nodal_balance(m::Model, flow, trans, timeslicemap)
    #@butcher 
	for (n) in node(), t in keys(timeslicemap)
        @constraint(
            m,
            # Change in the state commodity content
			0
            ==
            # Demand for the commodity
            - ( demand(node=n, t=1) != nothing &&
                demand(node=n, t=1)
                )
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
