function initialize_cost_terms!(m)
    m.ext[:cost_terms] = Dict()
    m.ext[:cost_terms_fun] = Dict()
    cost_terms = [
        :variable_om_costs,
        :fixed_om_costs,
        :taxes,
        :operating_costs,
        :fuel_costs,
        :start_up_costs,
        :shut_down_costs,
        :objective_penalties,
        :connection_flow_costs,
        :renewable_curtailment_costs,
        :res_proc_costs,
        :ramp_costs
        :total_costs
    ]
    for cost_term in cost_terms
        m.ext[:cost_terms][cost_term] = Dict()
    end
    for cost_term in cost_terms
        m.ext[:cost_terms_fun] = [eval(cost_terms) for cost_terms in keys(m.ext[:cost_terms])]
    end
    #TODO:add ramp_costs
end

function save_objective_values!(m)
    ind = (model=model()[1], t=current_window)
    for key in keys(m.ext[:cost_terms])
        save_cost_term!(m, key, ind)
    end
end

function save_cost_term!(m, name, ind)
    fun = eval(name)
    m.ext[:cost_terms][name] = Dict(
        ind => value(realize(fun(m,end_(ind.t))))
    )
end
