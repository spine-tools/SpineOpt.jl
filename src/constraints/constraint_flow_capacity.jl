function constraint_flow_capacity(m::Model, flow)
    @constraint(
        m,
        [
            u in unit(),
            n in node(),
            t=1:number_of_timesteps(time="timer");
            unit_capacity(unit=u) != nothing
        ],
        + sum(flow[c, n, u, "out", t] for c in cap_def__commodity(unit=u)
            if [n, "out"] in commodity__node__unit__direction(commodity=c, unit=u))
        + sum(flow[c, n, u, "in", t] for c in cap_def__commodity(unit=u)
            if [n, "in"] in commodity__node__unit__direction(commodity=c, unit=u))
        <=
        + avail_factor(unit=u, t=t)
            * unit_conv_cap_to_flow(unit=u)
            * unit_capacity(unit=u)
    )
end
