function minimize_production_cost(m::Model, flow,time)
    production_cost = zero(AffExpr)
    for t=1:length(time)
        for u in unit()
            for c in unit_output_commodity(u)
                production_cost += flow[c, u, "out", t] * conversion_cost(u)
            end
            for c in unit_input_commodity(u)
                production_cost += flow[c, u, "in", t] * conversion_cost(u)
            end
        end
    end
    @objective(m, Min, production_cost)
end
