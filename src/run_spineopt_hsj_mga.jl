#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

import DataStructures: DefaultDict

function do_run_spineopt!(
    m,
    url_out,
    ::Val{:hsj_mga_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    return generic_run_mga!(m, url_out, Val(:hsj_mga_algorithm), log_level, update_names, alternative)
end

function do_run_spineopt!(
    m,
    url_out,
    ::Val{:fuzzy_mga_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    return generic_run_mga!(m, url_out, Val(:fuzzy_mga_algorithm), log_level, update_names, alternative)
end

function do_run_spineopt!(
    m,
    url_out,
    ::Val{:multithreshold_mga_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    return generic_run_mga!(m, url_out, Val(:multithreshold_mga_algorithm), log_level, update_names, alternative)
end

function generic_run_mga!(m::Model, url_out, algorithm_type::Val, log_level, update_names, alternative)
    instance = m.ext[:spineopt].instance 
    mga_iteration = ObjectClass(:mga_iteration, [])
    build_model!(m; log_level)
    m.ext[:spineopt].expressions[:variable_group_values] = iterative_mga!(
        m, 
        m.ext[:spineopt].variables,
        prepare_variable_groups(m),
        something(max_mga_iterations(model=instance), 0),
        max_mga_slack(model=instance),
        (m) -> total_costs(m, anything),
        algorithm_type,
        (m; iteration) ->  solve_model!(
                m;
                log_level=log_level,
                update_names=update_names,
                output_suffix=_add_mga_iteration(iteration, mga_iteration),
            ),
    )
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    return m
end

function _add_mga_iteration(k, mga_iteration)
    new_mga_name = Symbol(:mga_it_, k)
    new_mga_i = Object(new_mga_name, :mga_iteration)
    add_object!(mga_iteration, new_mga_i)
    (mga_iteration=mga_iteration(new_mga_name),)
end

struct mga_group_param
    stochastic_indices_of_variable::Function
    scenario_weights::Function
    variable_indices::AbstractArray
end

"""
    Runs the itertive mga process.

    # Arguments:
    - m::Model - JuMP model
    - variables::AbstractDict - dict that returns a dict with scenario variable for an mga group
    - group_parameters::AbstractDict - dict of parameters for every mga variable group
    - max_mga_iters::Int - no mga iterations
    - mga_slack::Float64 - slack for near optimality exploration
    - goal_function::Function - function returning an expression for the objective funtcion
    - algorithm_type::Val - value for multiple dispatch
    - solve_wrapper::Function - wrapper that runs the optimization and returns boolean value with status
"""
function iterative_mga!(
    m::Model, 
    variables,
    group_parameters::AbstractDict{Symbol, mga_group_param},
    max_mga_iters::Int,
    mga_slack::Float64,
    goal_function::Function,
    algorithm_type::Val,
    solve_wrapper::Function = (m; iteration) -> (optimize!(m); true),
)   
    group_variable_values = Dict()
    hsj_weights = init_hsj_weights()
    solve_wrapper(m; iteration=0)
    group_variable_values[0] = get_variable_group_values(variables, group_parameters)
    update_hsj_weights!(group_variable_values[0], hsj_weights, group_parameters)
    slack = slack_correction(mga_slack, objective_value(m))
    constraint = add_mga_objective_constraint!(m, slack, goal_function, algorithm_type)
    for i=1:max_mga_iters
        update_mga_objective!(m, hsj_weights, variables, group_variable_values[i-1], group_parameters, constraint, algorithm_type)
        solve_wrapper(m; iteration=i) || break
        group_variable_values[i] = get_variable_group_values(variables, group_parameters)
        update_hsj_weights!(group_variable_values[i], hsj_weights, group_parameters)
    end
    return group_variable_values
end

function prepare_variable_groups(m::Model)
    return Dict(
        :units_invested  => mga_group_param(
            (ind) -> units_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(unit_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            units_invested_mga_indices()
        ),
        :connections_invested  => mga_group_param(
            (ind) -> connections_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(connection_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            connections_invested_mga_indices(),
        ),
        :storages_invested  => mga_group_param(
            (ind) -> storages_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(node_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            storages_invested_mga_indices(),
        ),
    )
end

"""

    Retrieves values of mga variables and stores them in the returned dict.

    # Arguments
    - variables::Dict{Symbol, Any} - dict of variable group indexed variables
    - group_parameters::Dict{Symbol, mga_group_param} - dict of parameters for every mga variable group
"""
function get_variable_group_values(variables::AbstractDict, group_parameters::AbstractDict{Symbol, mga_group_param})
    return Dict(
        group_name => Dict(
            var_idx => value(variables[group_name][var_idx]) 
            for i in group.variable_indices for var_idx in group.stochastic_indices_of_variable(i)
        ) for (group_name, group) in group_parameters
    )
end

"""
    Reformulates mga objective based on new variable values.

    # Arguments:
    - m::Model - JuMP model
    - hsj_weights::AbstractDict - dict that returns a dict with mga weights per variable for an mga group key
    - variables::AbstractDict - dict that returns a dict with scenario variable for an mga group
    - variable_values::AbstractDict - dict that returns a dict with scenario variable values for an mga group
    - group_parameters::AbstractDict - dict that returns mga params for an mga group
    - objective_constraint::AbstractDict - dict that describes mga near optimality constraint
    - algorithm_type::Val - value for multiple dispatch
"""
function update_mga_objective!(
    m::Model,
    hsj_weights::AbstractDict,
    variables::AbstractDict,
    variable_values::AbstractDict,
    group_parameters::AbstractDict{Symbol, mga_group_param},
    objective_constraint::AbstractDict,
    algorithm_type::Val
)
    mga_weighted_groups = Dict(
        group_name => prepare_objective_mga!(
            m,
            group.stochastic_indices_of_variable,
            group.scenario_weights,
            group.variable_indices,
            variables[group_name],
            variable_values[group_name],
            hsj_weights[group_name],
            algorithm_type
        ) for (group_name, group) in group_parameters
    )
    return formulate_mga_objective!(m, mga_weighted_groups, keys(group_parameters), objective_constraint, algorithm_type)
end

"""
    Minimizes the sum of all mga group sums

    # Arguments
    - m::Model - JuMP model
    - mga_weighted_groups::AbstractDict - dict with expressions representing each variable group (s_i)
    - group_names - iterator with group names
    - objective_constraint::AbstractDict - dict representing the near optimality constraint

"""
function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    group_names,
    objective_constraint::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)
    # we minimize the sum of all variable group weighted sums
    return Dict(
        :objective => @objective(m, Min, sum(mga_weighted_groups[mga_group][:expression] for mga_group in group_names))
    )
end

"""
    Creates the fuzzy rpm formulation - lexmax (min_i s_i, ∑_i s_i) where s_i is the achievement function for ith objective.

    # Arguments
    - m::Model - JuMP model
    - mga_weighted_groups::AbstractDict - dict with expressions representing each variable group (s_i)
    - group_names - iterator with group names
    - objective_constraint::AbstractDict - dict representing the near optimality constraint
    - eps - small constant for efficient lexmax implementation
"""
function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    group_names,
    objective_constraint::AbstractDict,
    ::Val{:fuzzy_mga_algorithm},
    eps=1e-4    
)   
    formulation = Dict()
    # we maximize the minimum of all the achievement functions
    formulation[:variable] = s_min = @variable(m)
    for mga_group in group_names
        formulation[mga_group] = @constraint(m, s_min <= mga_weighted_groups[mga_group][:variable])
    end
    formulation[:objective_constraint] = @constraint(m, s_min <= objective_constraint[:variable])
    # RPM objective function - an implementation of lexmax of the minimum of achievement functions, regularized with a sum
    formulation[:objective] = @objective(
        m,
        Max,
        s_min + eps * sum(mga_weighted_groups[mga_group][:variable] for mga_group in group_names) + eps * objective_constraint[:variable]
    )
    return formulation
end


formulate_mga_objective!(m, groups, names, constr, ::Val{:multithreshold_mga_algorithm}) = formulate_mga_objective!(m, groups, names, constr, Val(:fuzzy_mga_algorithm)) 

"""
    Creates a weighted mga for variables from a single mga group
    
    # Arguments
    - m::Model - JuMP model
    - stochastic_indices_of_variable::Function - returns iterator of scenario variable indices for a variable
    - variable_scenario_weights::Function - returns scenario weights
    - variable_indices::AbstractArray - all variable indices from a variable group
    - variable - dict with JuMP scenario variables
    - variable_values::AbstractDict - dict with values of variables from previous iteration
    - mga_weights::AbstractDict - mga weights from a previous iteration
"""
function prepare_objective_mga!(
    m::Model,
    stochastic_indices_of_variable::Function,
    variable_scenario_weights::Function,
    variable_indices::AbstractArray,
    variable,
    variable_values::AbstractDict,
    mga_weights::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)   
    # mga variables with appropriate weights
    weighted_group_variables = (
        get_scenario_variable_average(variable, stochastic_indices_of_variable(i), variable_scenario_weights) * mga_weights[i]
        for i in variable_indices
    )
    # our objective is a sum of all the mga weighted variables
    return Dict(:expression => @expression(m, sum(weighted_group_variables, init=0)))
end

"""
    Creates a fuzzy objective for one of the variable groups.
    
    # Arguments
    - m::Model - JuMP model
    - stochastic_indices_of_variable::Function - returns iterator of scenario variable indices for a variable
    - variable_scenario_weights::Function - returns scenario weights
    - variable_indices::AbstractArray - all variable indices from a variable group
    - variable - dict with JuMP scenario variables
    - variable_values::AbstractDict - dict with values of variables from previous iteration
    - mga_weights::AbstractDict - mga weights from a previous iteration
    - beta - constant to control the slope of the achievement function after reaching aspiration
    - gamma - constant to control the slope of the achievement function before reaching reservation 
"""
function prepare_objective_mga!(
    m::Model,
    stochastic_indices_of_variable::Function,
    variable_scenario_weights::Function,
    variable_indices::AbstractArray,
    variable,
    variable_values::AbstractDict,
    mga_weights::AbstractDict,
    ::Val{:fuzzy_mga_algorithm},
    beta=0.5,
    gamma=1.5
)   
    # mga variables with appropriate weights
    weighted_group_variables = (
        get_scenario_variable_average(variable, stochastic_indices_of_variable(i), variable_scenario_weights) * mga_weights[i]
        for i in variable_indices
    )
    # values of mga expressions in current point
    weighted_group_variable_values = (
        get_scenario_variable_average(variable_values, stochastic_indices_of_variable(i), variable_scenario_weights) * mga_weights[i]
        for i in variable_indices
    )
    a::Float64 = 0 # we aspire to zero out all of the nonzero variables
    y = sum(weighted_group_variables, init=0) # mga sum expression
    r::Float64 = sum(weighted_group_variable_values, init=0) # we start to get satsfied after the point of no change
    # we create an achievement function for every variable group
    return add_rpm_constraint!(m, y, a, r, beta, gamma)
end


function prepare_objective_mga!(
    m::Model,
    stochastic_indices_of_variable::Function,
    variable_scenario_weights::Function,
    variable_indices::AbstractArray,
    variable,
    variable_values::AbstractDict,
    mga_weights::AbstractDict,
    ::Val{:multithreshold_mga_algorithm},
    beta=0.5,
    gamma=1.5
)   
    return prepare_objective_mga!(
        m,
        stochastic_indices_of_variable,
        variable_scenario_weights,
        variable_indices,
        variable,
        variable_values,
        mga_weights,
        Val(:fuzzy_mga_algorithm),
        beta,
        gamma
    )
end


"""
    Gets scenario variables averaged with their weights

    # Arguments
    - variable - dict of scenario variables
    - variable_indices - iterator with indexes for our variable
    - scenario_weights - returns the weight of scenario
"""
function get_scenario_variable_average(variable, variable_indices, scenario_weights::Function)
    return sum(variable[i] * scenario_weights(i) for i in variable_indices)
end

"""
    Adds a constraint that forces nearly optimal solutions

    # Arguments
    - m::Model - JuMP model
    - slack::Float64 - how many percents can we stray from the optimal value
    - goal_function - function that return the objective value expression for our model
"""
function add_mga_objective_constraint!(m::Model, slack::Float64, goal_function::Function, ::Val{:hsj_mga_algorithm})
    return Dict(:eps_constraint => @constraint(m, goal_function(m) <= (1 + slack) * objective_value(m)))
end

"""
    Adds constraints used by the Reference Point Method. Additional variable corresponds to achievement criterion

    # Arguments
    - m::Model - JuMP model
    - expression - a JuMP expression that corresponds to a single goal function
    - aspiration - value that we would like to achieve on that goal function
    - reservation - minimal value of the expression that starts to satisfy us
    - beta - constant to control the slope of the achievement function after reaching aspiration
    - gamma - constant to control the slope of the achievement function before reaching reservation 
"""
function add_mga_objective_constraint!(m::Model, slack::Float64, goal_function::Function, ::Val{:fuzzy_mga_algorithm}, beta=0.5, gamma=1.5)
    y = goal_function(m)
    a = objective_value(m) # we aspire to reach the best possible value
    r = (1 + slack) * objective_value(m) # we start to get satsfied when reaching nearly optimal solution
    return add_rpm_constraint!(m, y, a, r, beta, gamma)
end

"""
    Adds constraints used by the multithreshold Reference Point Method. Additional variable corresponds to achievement criterion

    # Arguments
    - m::Model - JuMP model
    - expression - a JuMP expression that corresponds to a single goal function
    - aspiration - value that we would like to achieve on that goal function
    - reservation - minimal value of the expression that starts to satisfy us
    - beta - constant to control the slope of the achievement function after reaching aspiration
    - gamma - constant to control the slope of the achievement function before reaching reservation
    - n_thresholds - number of tresholds to be added
"""
function add_mga_objective_constraint!(m::Model, slack::Float64, goal_function::Function, ::Val{:multithreshold_mga_algorithm}, beta=0.5, gamma=1.5, n_thresholds=4)
    y = goal_function(m)
    a = objective_value(m) # we aspire to reach the best possible value
    slacks = [slack / 2^i for i in 0:n_thresholds-1]
    ts = [(1+eps) * objective_value(m) for eps in slacks]
    push!(ts, objective_value(m)) # we aspire to reach the best possible value
    return add_rpm_constraint!(m, y, ts, beta, gamma)
end

"""
    Adds constraints used by the Reference Point Method. Additional variable corresponds to achievement criterion

    # Arguments
    - m::Model - JuMP model
    - expression - a JuMP expression that corresponds to a single goal function
    - aspiration - value that we would like to achieve on that goal function
    - reservation - minimal value of the expression that starts to satisfy us
    - beta - constant to control the slope of the achievement function after reaching aspiration
    - gamma - constant to control the slope of the achievement function before reaching reservation 
"""
function add_rpm_constraint!(m::Model, expression, aspiration::Float64, reservation::Float64, beta::Float64=0.5, gamma::Float64=1.5)
    if !(0 < beta < 1 < gamma)
        throw(DomainError((beta, gamma), "parameters not in the domain 0 < beta < 1 < gamma"))
    end
    s = @variable(m)
    # If the values of aspiration and reservation are too close, we ensure that the objective is always fully satisfiable
    if isapprox(aspiration, reservation)
        thresholds = Dict(i => @constraint(m, s <= 1) for i=0:2)
    else
        thresholds = Dict(
            0 => @constraint(m, s <= gamma * (expression - reservation) / (aspiration - reservation)),
            1 => @constraint(m, s <= (expression - reservation) / (aspiration - reservation)),
            2 => @constraint(m, s <=  1 + beta * (expression - aspiration) / (aspiration - reservation))
        )
    end
    return Dict(:variable => s, :thresholds => thresholds)
end

"""
    Adds multithreshold constraints used by the Reference Point Method. Additional variable corresponds to achievement criterion

    # Arguments
    - m::Model - JuMP model
    - expression - a JuMP expression that corresponds to a single goal function
    - thresholds - values of the expression that cross an appropriate threshold of satisfaction, from the worst to the best
    - beta - constant to control the slope of the achievement function after reaching aspiration
    - gamma - constant to control the slope of the achievement function before reaching reservation 
"""
function add_rpm_constraint!(m::Model, expression, thresholds::Vector{Float64}, beta::Float64=0.5, gamma::Float64=1.5)
    if !(0 < beta < 1 < gamma)
        throw(DomainError((beta, gamma), "parameters not in the domain 0 < beta < 1 < gamma"))
    end
    n_thresholds = length(thresholds)
    if n_thresholds < 2
        throw(DomainError(thresholds, "there should be at least two thresholds!"))
    end
    if !issorted(thresholds, rev=true) && !issorted(thresholds)
        throw(DomainError(thresholds, "thresholds should be sorted!"))
    end
    s = @variable(m)
    # If the values of two thresholds are too close, we ensure that the objective is always fully satisfiable
    if any(isapprox(thresholds[j+1], thresholds[j]) for j=1:n_thresholds-1)
        thresh_constraints = Dict(i=>@constraint(m, s <= 1) for i=0:n_thresholds)
    else
        normalization_coef = abs(thresholds[end]-thresholds[1]) / sum((thresholds[i] - thresholds[i-1])^2 for i=2:n_thresholds)
        betas = Dict(j=>normalization_coef * abs(thresholds[j+1] - thresholds[j]) for j=1:n_thresholds-1)
        betas[0] = gamma * betas[1]
        betas[n_thresholds] = beta * betas[n_thresholds-1]
        thresh_constraints = Dict(
            j=>@constraint(
                m,
                s <= betas[j] * (expression - thresholds[j])/(thresholds[end]-thresholds[1]) +
                sum(betas[k-1] * (thresholds[k] - thresholds[k-1])/(thresholds[end]-thresholds[1]) for k=2:j)
            ) 
            for j=1:n_thresholds
        )
        thresh_constraints[0] = @constraint(
            m,
            s <= betas[0] * (expression - thresholds[1])/(thresholds[end]-thresholds[1])
        )
    end
    return Dict(:variable => s, :thresholds => thresh_constraints)
end

"If the objective value was negative, the f(x) <= (1+slack) * f(x_optim_ would be infeasible unless we negate the value of slack"
slack_correction(raw_slack::Float64, objective_value) = objective_value >= 0 ? raw_slack : -raw_slack

init_hsj_weights() = DefaultDict{Symbol, AbstractDict}(() -> DefaultDict(0))

"""
    Updates the weights in the passed dict according to the Hop Skip Jump scheme, in all mga groups

    # Arguments
    - variable_values::AbstractDict{Symbol, AbstractDict} - dict of all variable_values from previous iteration
    - variable_hsj_weights::AbstractDict{Symbol, AbstractDict} - dict of all mga weights
    - group_parameters::AbstractDict{Symbol, mga_group_param} - dict of all group parameters
"""
function update_hsj_weights!(
    variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict{Symbol, AbstractDict},
    group_parameters::AbstractDict{Symbol, mga_group_param}
)
    for (group_name, group) in group_parameters
        do_update_hsj_weights!(
            group.variable_indices,
            group.stochastic_indices_of_variable,
            variable_values[group_name],
            variable_hsj_weights[group_name]
        )
    end
end

"""    
    Updates the weights in the passed dict according to the Hop Skip Jump scheme.
    Variables that were nonzero in a iteration before have their weights set to 1. Previous weights aren't cleared.

    # Arguments
    - variable_indices::AbstractArray - indices of all variable in a single group
    - all_variable_values::AbstractDict - dict of all variable scenario values from a single group, from previous iteration
    - variable_scenario_indices::Function - returns all stochastic indices for a single variable
    - variable_hsj_weights::AbstractDict - dict of mga weights to be updated
"""
function do_update_hsj_weights!(
    variable_indices::AbstractArray,
    variable_scenario_indices::Function,
    all_variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict
)
    active_variables = filter(i -> was_variable_active(all_variable_values, variable_scenario_indices(i)), variable_indices)
    for i in active_variables
        variable_hsj_weights[i] = 1
    end

end

"""
    Checks if variable was nonzero in any of the scenarios.

    # Arguments
    - all_variable_values::AbstractDict - dict of all variable scenario values from a single group, from previous iteration
    - variable_indices - iterator or array with stochastic indices for a single variable
"""
function was_variable_active(all_variable_values::AbstractDict, variable_indices)
    return any(all_variable_values[i] > 0 for i in variable_indices)
end