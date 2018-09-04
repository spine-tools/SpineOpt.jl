function constraint_FlowCapacity(m::Model, flow)
    @constraint(m, [c in commodity(), u in unit(),n in node(), d in direction(), t=1:number_of_timesteps(time="timer"); all([[c,n,u,d] in commodity_node_unit_direction(),!(p_UnitCapacity(unit=u,commodity=c)===nothing),!(p_NumberOfUnits(unit = u)===nothing),!(p_UnitConvCapToFlow(unit=u, commodity=c)===nothing),!(p_AF(unit=u,t=t)===nothing)])],
        + flow[c,n, u, d, t]
        <=
        + p_AF(unit=u,t=t)
            * p_UnitCapacity(unit=u,commodity = c)
            * p_NumberOfUnits(unit = u)
            * p_UnitConvCapToFlow(unit=u, commodity = c)
    )
end
