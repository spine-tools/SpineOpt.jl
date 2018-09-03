# FIXME: commodity_node_unit_direction will need to be renamed using double underscores
function generate_variable_flow(m::Model)
    @variable(
        m,
        flow[
            c in commodity(),
            n in node(),
            u in unit(),
            d in direction(),
            t = 1:number_of_timesteps(time="timer");
            [c, n, u, d] in commodity_node_unit_direction()
        ] >= 0
    )
end
