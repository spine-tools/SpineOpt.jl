# FIXME: some names here don't respect the lower_case convention
function constraint_commodity_balance(m::Model, flow, trans)
    @constraint(m, [n in node(), t=1:number_of_timesteps(time="timer"); p_Demand(node=n, t=t) != nothing],
        + sum(flow[c, n, u, "out", t] for u in unit(), c in commodity()
            if [n, "out"] in commodity_node_unit_direction(unit=u, commodity=c))
        ==
        + p_Demand(node=n, t=t)
        + sum(flow[c, n, u, "in", t] for u in unit(), c in commodity()
            if [n, "in"] in commodity_node_unit_direction(unit=u, commodity=c))
        + sum(trans[k, n, j, t] for k in connection(), j in node()
            if [n] in connection_node_node(connection=k, node2=j))
    )
    @constraint(m, [n in node(), t=1:number_of_timesteps(time="timer"); p_Demand(node=n, t=t) != nothing],
        + sum(flow[c, n, u, "out", t] for u in unit(), c in commodity()
            if [n, "out"] in commodity_node_unit_direction(unit=u, commodity=c))
        ==
        + sum(flow[c, n, u, "in", t] for u in unit(), c in commodity()
            if [n, "in"] in commodity_node_unit_direction(unit=u, commodity=c))
        + sum(trans[k, n, j, t] for k in connection(), j in node()
            if [n] in connection_node_node(connection=k, node2=j))
    )
end
