function capacity(m::Model, flow)
    @constraint(m, [u in unit(),n in node(), t=1:number_of_timesteps("timer"); !isnull(UnitCapacity(u))],
        + sum(flow[c,n, u, "out", t] for c in capa_defining_com(u) if all([c in output_com(u), n in CommodityAffiliation(c), n in NodeUnitConnection(u)]))
        + sum(flow[c,n, u, "in", t] for c in capa_defining_com(u)  if all([c in input_com(u), n in CommodityAffiliation(c), n in NodeUnitConnection(u)]))
        <= AF(u) * CapToFlow(u) * UnitCapacity(u)
    )
end
