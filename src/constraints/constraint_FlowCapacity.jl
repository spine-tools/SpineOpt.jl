function constraint_FlowCapacity(m::Model, flow)
    @constraint(m, [u in unit(),n in node(), t=1:number_of_timesteps(time="timer"); !isnull(p_UnitCapacity(unit=u))],
        + sum(flow[c,n, u, "out", t] for c in cap_def_commodity(unit=u) if [c,n,u,"out"] in generate_CommoditiesNodesUnits())
        + sum(flow[c,n, u, "in", t] for c in cap_def_commodity(unit=u) if [c,n,u,"in"] in generate_CommoditiesNodesUnits())
        <=
        + p_AF(unit=u,t=t)
            * p_UnitConvCapToFlow(unit=u)
            * p_UnitCapacity(unit=u)
    )
end
