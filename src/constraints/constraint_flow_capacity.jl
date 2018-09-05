function constraint_flow_capacity(m::Model, flow)
    @constraint(
        m,
        [
            c in commodity(),
            u in unit(),
            n in node(),
            d in direction(),
            t=1:number_of_timesteps(time="timer");
            all([
                        [c,n,u,d] in commodity__node__unit__direction(),
                        unit_capacity(unit=u,commodity=c) != nothing,
                        number_of_units(unit = u) != nothing,
                        unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
                        avail_factor(unit=u,t=t) != nothing
            ])
        ],
        + flow[c, n, u, d, t]
        <=
        + avail_factor(unit=u, t=t)
            * unit_capacity(unit=u,commodity = c)
                        * number_of_units(unit = u)
                                    * unit_conv_cap_to_flow(unit=u, commodity = c)

    )
end
