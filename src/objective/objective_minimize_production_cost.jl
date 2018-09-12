"""
    objective_minimize_production_cost(m::Model, flow)

Minimize the `production_cost` correspond to the sum over all
`conversion_cost` of each `unit`.
"""
function objective_minimize_production_cost(m::Model, flow)
    production_cost=zero(AffExpr)
    for t=1:number_of_timesteps(time="timer")
        for (c, n, u, d) in commodity__node__unit__direction()
            if conversion_cost(unit=u, commodity=c) != nothing
                production_cost += flow[c, n, u, d, t] * conversion_cost(unit=u, commodity=c, t=t)
            end
        end
    end
    @objective(m, Min, production_cost)
end
