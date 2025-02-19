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

function generic_run_mga!(m::Model, url_out, algorithm_type::Val, log_level, update_names, alternative)
    instance = m.ext[:spineopt].instance 
    mga_iteration = ObjectClass(:mga_iteration, [])
    build_model!(m; log_level)
    variable_group_values = iterative_mga!(
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

function iterative_mga!(
    m::Model, 
    variables,
    variable_group_parameters::AbstractDict,
    max_mga_iters::Int,
    mga_slack::Float64,
    goal_function::Function,
    algorithm_type::Val,
    solve_wrapper::Function = (m; iteration) -> (optimize!(m); true),
)   
    group_variable_values = Dict()
    hsj_weights = init_hsj_weights()
    solve_wrapper(m; iteration=0)
    group_variable_values[0] = get_variable_group_values(variables, variable_group_parameters)
    update_hsj_weights!(group_variable_values[0], hsj_weights, variable_group_parameters)
    slack = slack_correction(mga_slack, objective_value(m))
    constraint = add_mga_objective_constraint!(m, slack, goal_function, algorithm_type)
    for i=1:max_mga_iters
        update_mga_objective!(m, hsj_weights, variables, group_variable_values[i-1], variable_group_parameters, constraint, algorithm_type)
        solve_wrapper(m; iteration=i) || break
        group_variable_values[i] = get_variable_group_values(variables, variable_group_parameters)
        update_hsj_weights!(group_variable_values[i], hsj_weights, variable_group_parameters)
    end
    return group_variable_values
end

function prepare_variable_groups(m::Model)
    return Dict(
        :units_invested  => (
            (ind) -> units_invested_available_indices(m; ind...),
            (stoch_ind) -> unit_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...),
            units_invested_mga_indices,
        ),
        :connections_invested  => (
            (ind) -> connections_invested_available_indices(m; ind...),
            (stoch_ind) ->connection_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...),
            connections_invested_mga_indices,
        ),
        :storages_invested  => (
            (ind) -> storages_invested_available_indices(m; ind...),
            (stoch_ind) -> node_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...),
            storages_invested_mga_indices,
        ),
    )
end

function get_variable_group_values(variables, variable_group_parameters)
    return Dict(
        group_name => Dict(
            var_idx => value(variables[group_name][var_idx]) 
            for i in mga_indices_func() for var_idx in available_indices(i)
        ) for (group_name, (available_indices, _, mga_indices_func)) in variable_group_parameters
    )
end

function update_mga_objective!(
    m::Model,
    hsj_weights::AbstractDict,
    variables::AbstractDict,
    variable_values::AbstractDict,
    group_parameters::AbstractDict,
    objective_constraint::AbstractDict,
    algorithm_type::Val
)
    mga_weighted_groups = Dict(
        group_name => prepare_objective_mga!(
            m,
            variables[group_name],
            variable_values[group_name],
            available_indices,
            scenario_weights,
            mga_indices_func(),
            hsj_weights[group_name],
            algorithm_type
        ) for (group_name, (available_indices, scenario_weights, mga_indices_func)) in group_parameters
    )
    return formulate_mga_objective!(m, mga_weighted_groups, keys(group_parameters), objective_constraint, algorithm_type)
end

function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    group_names,
    objective_constraint::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)
    return Dict(
        :objective => @objective(m, Min, sum(mga_weighted_groups[mga_group][:expression] for mga_group in group_names))
    )
end

function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    group_names,
    objective_constraint::AbstractDict,
    ::Val{:fuzzy_mga_algorithm},
    eps=1e-4    
)   
    formulation = Dict()
    formulation[:variable] = s_min = @variable(m)
    for mga_group in group_names
        formulation[mga_group] = @constraint(m, s_min <= mga_weighted_groups[mga_group][:variable])
    end
    formulation[:objective_constraint] = @constraint(m, s_min <= objective_constraint[:variable])
    formulation[:objective] = @objective(
        m,
        Max,
        s_min + eps * sum(mga_weighted_groups[mga_group][:variable] for mga_group in group_names) + eps * objective_constraint[:variable]
    )
    return formulation
end


function prepare_objective_mga!(
    m::Model,
    variable,
    variable_values::AbstractDict,
    variable_indices::Function,
    variable_stochastic_weights::Function,
    mga_indices::AbstractArray,
    mga_weights::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)   
    weighted_group_variables = (
        get_scenario_variable_average(variable, variable_indices(i), variable_stochastic_weights) * mga_weights[i]
        for i in mga_indices
    )
    return Dict(:expression => @expression(m, sum(weighted_group_variables, init=0)))
end

function prepare_objective_mga!(
    m::Model,
    variable,
    variable_values::AbstractDict,
    variable_indices::Function,
    variable_stochastic_weights::Function,
    mga_indices::AbstractArray,
    mga_weights::AbstractDict,
    ::Val{:fuzzy_mga_algorithm},
    beta=0.5,
    gamma=1.5
)   
    weighted_group_variables = (
        get_scenario_variable_average(variable, variable_indices(i), variable_stochastic_weights) * mga_weights[i]
        for i in mga_indices
    )
    weighted_group_variable_values = (
        get_scenario_variable_average(variable_values, variable_indices(i), variable_stochastic_weights) * mga_weights[i]
        for i in mga_indices
    )
    a = 0
    y = sum(weighted_group_variables, init=0)
    r = sum(weighted_group_variable_values, init=0)
    return add_rpm_constraint!(m, y, a, r, beta, gamma)
end

function get_scenario_variable_average(variable, variable_indices, scenario_weights::Function)
    return sum(variable[i] * scenario_weights(i) for i in variable_indices)
end

function add_mga_objective_constraint!(m::Model, slack::Float64, goal_function::Function, ::Val{:hsj_mga_algorithm})
    return Dict(:eps_constraint => @constraint(m, goal_function(m) <= (1 + slack) * objective_value(m)))
end

function add_mga_objective_constraint!(m::Model, slack::Float64, goal_function::Function, ::Val{:fuzzy_mga_algorithm}, beta=0.5, gamma=1.5)
    y = goal_function(m)
    a = objective_value(m)
    r = (1 + slack) * objective_value(m)
    return add_rpm_constraint!(m, y, a, r, beta, gamma)
end

function add_rpm_constraint!(m::Model, expression, aspiration, reservation, beta=0.5, gamma=1.5)
    if !(0 < beta < 1 < gamma)
        throw(DomainError((beta, gamma), "parameters not in the domain 0 < beta < 1 < gamma"))
    end
    s = @variable(m)
    if isapprox(aspiration, reservation)
        c1 = c2 = c3 = @constraint(m, s <= 1)
    else
        c1 = @constraint(m, s <= gamma * (expression - reservation) / (aspiration - reservation))
        c2 = @constraint(m, s <= (expression - reservation) / (aspiration - reservation))
        c3 = @constraint(m, s <=  1 + beta * (expression - aspiration) / (aspiration - reservation))
    end
    return Dict(:variable => s, :threshold1 => c1, :threshold2 => c2, :threshold3 => c3)
end

function slack_correction(raw_slack::Float64, objective_value)
    return objective_value >= 0 ? raw_slack : -raw_slack
end

function init_hsj_weights()
    return DefaultDict(() -> DefaultDict(0))
end

function update_hsj_weights!(
    variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict,
    group_parameters::AbstractDict
)
    for (group_name, (available_indices, _, mga_indices_func)) in group_parameters
        do_update_hsj_weights!(
            mga_indices_func(),
            variable_values[group_name],
            available_indices,
            variable_hsj_weights[group_name]
        )
    end
end

function do_update_hsj_weights!(
    mga_indices::AbstractArray,
    variable_values::AbstractDict,
    variable_indices::Function,
    variable_hsj_weights::AbstractDict
)
    for i in mga_indices
        if was_variable_active(variable_values, variable_indices(i))
            variable_hsj_weights[i] = 1
        end
    end
end

function was_variable_active(variable_values, variable_indices)
    return any(variable_values[i] > 0 for i in variable_indices)
end