function variable_flow(m::Model)
    @variable(m, flow[commodity(), unit(), ["in", "out"], t=1:24] >= 0)
end

function objective_minimize_production_cost(m::Model, flow)
    production_cost = zero(AffExpr)
    for t=1:24
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

function constraint_use_of_capacity(m::Model, flow)
    @constraint(m, [u in unit(), t=1:24; !isnull(capacity(u))],
        + sum(flow[c, u, "out", t] for c in unit_capacity_defining_commodity(u) if c in unit_output_commodity(u))
        + sum(flow[c, u, "in", t] for c in unit_capacity_defining_commodity(u) if c in unit_input_commodity(u))
        <= availability_factor(u) * capacity_to_flow(u) * capacity(u)
    )
end

function constraint_efficiency_definition(m::Model, flow)
    @constraint(m, [u in unit(), t=1:24; !isnull(ratio_output_input_flow(u))],
        + sum(flow[c, u, "out", t] for c in unit_output_commodity(u))
        == ratio_output_input_flow(u) * sum(flow[c, u, "in", t] for c in unit_input_commodity(u))
    )
end

function constraint_commodity_balance(m::Model, flow)
    @constraint(m, [c in commodity(), t=1:24],
        + sum(flow[c, u, "out", t] for u in unit_output_commodity(c))
        == demand("Leuven", t) + sum(flow[c, u, "in", t] for u in unit_input_commodity(c))
    )
end
