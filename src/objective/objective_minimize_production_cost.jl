# FIXME: some names here don't respect the lower_case convention
# FIXME: connection_node_node will need to be renamed using double underscores
# FIXME: We can't have direction as dimension in commodity__node__unit__direction,
# and at the same time as part of the name in p_ConversionCostIn, p_ConversionCostOut
function objective_minimize_production_cost(m::Model, flow)
    production_cost = zero(AffExpr)
    for t = 1:number_of_timesteps(time="timer")
        for (c, n, u, d) in commodity__node__unit__direction()
            if p_conversion_cost(unit=u, commodity=c) !=nothing
            production_cost += flow[c, n, u, d, t] * p_conversion_cost(unit=u, commodity=c)
            end
        end
    end
    @objective(m, Min, production_cost)
end
