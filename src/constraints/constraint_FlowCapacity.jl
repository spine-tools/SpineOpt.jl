# FIXME: some names here don't respect the lower_case convention
function constraint_FlowCapacity(m::Model, flow)
    @constraint(
        m,
        [
            u in unit(),
            n in node(),
            t=1:number_of_timesteps(time="timer");
            p_UnitCapacity(unit=u) != nothing
        ],
        + sum(flow[c, n, u, "out", t] for c in cap_def_commodity(unit=u)
            if [n, "out"] in commodity_node_unit_direction(commodity=c, unit=u))
        + sum(flow[c, n, u, "in", t] for c in cap_def_commodity(unit=u)
            if [n, "in"] in commodity_node_unit_direction(commodity=c, unit=u))
        <=
        + p_AF(unit=u, t=t)
            * p_UnitConvCapToFlow(unit=u)
            * p_UnitCapacity(unit=u)
    )
end
