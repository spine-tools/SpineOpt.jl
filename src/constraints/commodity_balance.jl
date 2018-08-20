function commodity_balance(m::Model,flow, trans,number_of_timesteps)
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps; !isnull(demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit() if [c,n,u,"out"] in get_com_node_unit())
        == demand(n, t) + sum(flow[c, n,u, "in", t] for u in unit() if [c,n,u,"in"] in get_com_node_unit())
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in get_all_connection_node_pairs())
    )
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps; isnull(demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit() if [c,n,u,"out"] in get_com_node_unit())
        == + sum(flow[c, n,u, "in", t] for u in unit() if [c,n,u,"in"] in get_com_node_unit())
    )
end

## helper to find all connection connected to a node
# for n in node()
#     demand(n) + sum(jfo["NodeConnectionRelationship"][n],trans) = sum(,flow)
#     jfo["NodeConnectionRelationship"][n]
# end
