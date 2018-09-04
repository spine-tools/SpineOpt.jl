function constraint_flow_capacity(m::Model, v_flow)
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
                        p_unit_capacity(unit=u,commodity=c) != nothing,
                        p_number_of_units(unit = u) != nothing,
                        p_unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
                        p_avail_factor(unit=u,t=t) != nothing
            ])
        ],
        + v_flow[c, n, u, d, t]
        <=
        + p_avail_factor(unit=u, t=t)
            * p_unit_capacity(unit=u,commodity = c)
                        * p_number_of_units(unit = u)
                                    * p_unit_conv_cap_to_flow(unit=u, commodity = c)

    )
end
