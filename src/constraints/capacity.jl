function capacity(m::Model, flow)
    @constraint(m, [u in unit(),n in node(), t=1:number_of_timesteps("timer"); !isnull(UnitCapacity(u))],
        + sum(flow[c,n, u, "out", t] for c in capa_defining_com(u) if [c,n,u,"out"] in get_com_node_unit())
        + sum(flow[c,n, u, "in", t] for c in capa_defining_com(u) if [c,n,u,"in"] in get_com_node_unit())
        <= AF(u) * CapToFlow(u) * UnitCapacity(u)
    )
end
