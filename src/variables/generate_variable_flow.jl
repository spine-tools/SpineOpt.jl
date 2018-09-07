"""
    generate_variable_flow(m::Model)

Generated `flow` variables for each existing pair of `[commodity,node,unit,direction]`.
"""
function generate_variable_flow(m::Model)
    @variable(
        m,
        flow[
            c in commodity(),
            n in node(),
            u in unit(),
            d in direction(),
            t=1:number_of_timesteps(time="timer");
            [c, n, u, d] in commodity__node__unit__direction()
        ] >= 0
    )
end
