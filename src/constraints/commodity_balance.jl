function commodity_balance(m::Model,flow, trans)
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps("timer"); !isnull(demand(n,t))],
        + sum(flow[c,n,u,"out",t] for u in NodeUnitConnection(n) if u in output_com(c))
        == 
        + demand(n,t) 
        + sum(flow[c,n,u,"in",t] for u in NodeUnitConnection(n) if u in input_com(c))
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in get_all_connection_node_pairs(true))
    )
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps("timer"); isnull(demand(n,t))],
        + sum(flow[c,n,u,"out",t] for u in NodeUnitConnection(n) if u in output_com(c))
        == 
        + sum(flow[c,n,u,"in",t] for u in NodeUnitConnection(n) if u in input_com(c))
    )
end

## helper to find all connection connected to a node
# for n in node()
#     demand(n) + sum(jfo["NodeConnectionRelationship"][n],trans) = sum(,flow)
#     jfo["NodeConnectionRelationship"][n]
# end
