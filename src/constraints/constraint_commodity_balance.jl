function constraint_commodity_balance(m::Model,flow, trans)
    @constraint(m, [n in node(), t=1:number_of_timesteps("timer"); !isnull(p_Demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit(), c in commodity() if [c,n,u,"out"] in generate_CommoditiesNodesUnits())
        ==
        + p_Demand(n, t) 
        + sum(flow[c, n,u, "in", t] for u in unit(), c in commodity() if [c,n,u,"in"] in generate_CommoditiesNodesUnits())
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in generate_ConnectionNodePairs())
    )
    @constraint(m, [n in node(), t=1:number_of_timesteps("timer"); isnull(p_Demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit(), c in commodity() if [c,n,u,"out"] in generate_CommoditiesNodesUnits())
        ==
        + sum(flow[c, n,u, "in", t] for u in unit(), c in commodity() if [c,n,u,"in"] in generate_CommoditiesNodesUnits())
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in generate_ConnectionNodePairs())
    )
end
