function minimize_production_cost(m::Model, flow,number_of_timesteps)
    production_cost = zero(AffExpr)
    for t=1:number_of_timesteps
        for u in unit()
            for c in output_com(u)
                production_cost += flow[c, u, "out", t] * conversion_cost(u)
            end
            for c in input_com(u)
                production_cost += flow[c, u, "in", t] * conversion_cost(u)
            end
        end
    end
    @objective(m, Min, production_cost)
end
