function minimize_production_cost(m::Model, flow)
    production_cost = zero(AffExpr)
    for t = 1:number_of_timesteps("timer")
        for c in commodity(), n in node(), u in unit()
            if [c,n,u,"in"] in get_com_node_unit()
                production_cost += flow[c,n,u,"in",t] * ConversionCost(u)
            end
            if [c,n,u,"out"] in get_com_node_unit()
                production_cost += flow[c,n,u,"out",t] * ConversionCost(u)
            end
        end
    end
    @objective(m, Min, production_cost)
end
