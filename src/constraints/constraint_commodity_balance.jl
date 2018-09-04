function constraint_commodity_balance(m::Model, v_flow, v_trans)
    @constraint(
        m,
        [
            n in node(),
            t=1:number_of_timesteps(time="timer");
            p_demand(node=n, t=t)!=nothing
        ],
        + sum(v_flow[c, n, u, "out", t] for u in unit(), c in commodity()
            if [n, "out"] in commodity__node__unit__direction(unit=u, commodity=c))
        ==
        + p_demand(node=n, t=t)
        + sum(v_flow[c, n, u, "in", t] for u in unit(), c in commodity()
            if [n, "in"] in commodity__node__unit__direction(unit=u, commodity=c))
        + sum(v_trans[k, n, j, t] for k in connection(), j in node()
            if [n] in connection__node__node(connection=k, node2=j))
    )
    @constraint(
        m,
        [
            n in node(),
            t=1:number_of_timesteps(time="timer");
            p_demand(node=n, t=t)==nothing
        ],
        + sum(v_flow[c, n, u, "out", t] for u in unit(), c in commodity()
            if [n, "out"] in commodity__node__unit__direction(unit=u, commodity=c))
        ==
        + sum(v_flow[c, n, u, "in", t] for u in unit(), c in commodity()
            if [n, "in"] in commodity__node__unit__direction(unit=u, commodity=c))
        + sum(v_trans[k, n, j, t] for k in connection(), j in node()
            if [n] in connection__node__node(connection=k, node2=j))
    )
end
