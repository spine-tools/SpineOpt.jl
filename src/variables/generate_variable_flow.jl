function generate_variable_flow(m::Model)
    @variable(
        m,
        v_flow[
            c in commodity(),
            n in node(),
            u in unit(),
            d in direction(),
            t = 1:number_of_timesteps(time="timer");
            [c, n, u, d] in commodity__node__unit__direction()
        ] >= 0
    )
end
