function objective_minimize_production_cost(m::Model, flow)
    production_cost = zero(AffExpr)
    for t = 1:number_of_timesteps(time="timer")
        for c in commodity(), n in node(), u in unit()
            if [c,n,u,"in"] in generate_CommoditiesNodesUnits()
                production_cost += flow[c,n,u,"in",t] * p_ConversionCostIn(unit=u,commodity=c)
            end
            if [c,n,u,"out"] in generate_CommoditiesNodesUnits()
                production_cost += flow[c,n,u,"out",t] * p_ConversionCostOut(unit=u,commodity=c)
            end
        end
    end
    @objective(m, Min, production_cost)
end
