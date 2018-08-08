function constraint_commodity_balance(m::Model, flow)
    @constraint(m, [c in commodity(),n in node(), t=1:number_of_timesteps],
        + sum(flow[c, n,u, "out", t] for u in unit_output_commodity(c))
        == demand("Leuven", t) + sum(flow[c, u, "in", t] for u in unit_input_commodity(c))
        + sum(trans[con,n,t] for con in connected_nodes(n))
    )
end

## helper to find all connection connected to a node
for n in node()
    demand(n) + sum(jfo["NodeConnectionRelationship"][n],trans) = sum(,flow)
    jfo["NodeConnectionRelationship"][n]
end
