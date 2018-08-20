function commodity_balance(m::Model,flow, trans)
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps("timer"); !isnull(demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit() if [c,n,u,"out"] in get_com_node_unit())
        == demand(n, t) + sum(flow[c, n,u, "in", t] for u in unit() if [c,n,u,"in"] in get_com_node_unit())
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in get_all_connection_node_pairs())
    )
    @constraint(m, [c in commodity(), n in CommodityAffiliation(c), t=1:number_of_timesteps("timer"); isnull(demand(n,t))],
        + sum(flow[c, n,u, "out", t] for u in unit() if [c,n,u,"out"] in get_com_node_unit())
        == + sum(flow[c, n,u, "in", t] for u in unit() if [c,n,u,"in"] in get_com_node_unit())
    )
end
