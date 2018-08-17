function minimize_production_cost(m::Model, flow,number_of_timesteps)
    production_cost = zero(AffExpr)
    for t = 1:number_of_timesteps
        for c in commodity()
            for n in node()
                for u in unit()
                    if all([n in CommodityAffiliation(c), u in input_com(c), u in NodeUnitConnection(n)])
                        production_cost += flow[c,n,u,"in",t] * ConversionCost(u)
                    end
                    if all([n in CommodityAffiliation(c), u in output_com(c), u in NodeUnitConnection(n)])
                        production_cost += flow[c,n,u,"out",t] * ConversionCost(u)
                    end
                end
            end
        end
    end
        @objective(m, Min, production_cost)
end
