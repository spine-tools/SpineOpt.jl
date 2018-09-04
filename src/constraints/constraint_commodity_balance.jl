function constraint_commodity_balance(m::Model,flow, trans)
    @constraint(m, [n in node(), t=1:number_of_timesteps(time ="timer"); !(p_Demand(node = n,t = t)===nothing)],
        + sum(flow[c, n,u, "out", t] for c in commodity(), u in unit() if [c,n,u] in commodity_node_unit_direction(direction = "out"))
        ==
        + p_Demand(node = n, t = t)
        + sum(flow[c, n,u, "in", t] for c in commodity(), u in unit() if [c,n,u] in commodity_node_unit_direction(direction = "in"))
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in connection_node_node())
    )
    @constraint(m, [n in node(), t=1:number_of_timesteps(time = "timer"); (p_Demand(node = n,t = t)===nothing)],
        + sum(flow[c, n,u, "out", t] for c in commodity(), u in unit() if [c,n,u] in commodity_node_unit_direction(direction = "out"))
        ==
        + sum(flow[c, n,u, "in", t] for c in commodity(), u in unit() if [c,n,u] in commodity_node_unit_direction(direction = "in"))
        + sum(trans[k,n,j,t] for k in connection(), j in node() if [k,n,j] in connection_node_node())
    )
end
