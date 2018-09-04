function objective_minimize_production_cost(m::Model, flow)
    production_cost = zero(AffExpr)
    for t = 1:number_of_timesteps(time="timer")
        for (c,n,u) in commodity_node_unit_direction(direction = "in")
            if !(p_ConversionCost(unit=u,commodity=c) === nothing)
                production_cost += flow[c,n,u,"in",t]  * p_ConversionCost(unit=u,commodity=c)
            end
        end
        for (c,n,u) in commodity_node_unit_direction(direction = "out")
            if !(p_ConversionCost(unit=u,commodity=c) === nothing)
                production_cost += flow[c,n,u,"out",t] * p_ConversionCost(unit=u,commodity=c)
            end
        end
    end
    @objective(m, Min, production_cost)
end
