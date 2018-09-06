"""
generate_variable_flow:
This function generated flow variables for each existing pair of [c,n,u,d]
    Note: d is the direction of flow,
     d=in: commodity flow into the unit (and vise versa)
"""
function generate_variable_flow(m::Model)
    @variable(
        m,
        flow[
            c in commodity(),
            n in node(),
            u in unit(),
            d in direction(),
            t = 1:number_of_timesteps(time = "timer");
            [c, n, u, d] in commodity__node__unit__direction()
        ] >= 0
    )
end
