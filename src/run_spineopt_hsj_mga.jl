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
    instance = m.ext[:spineopt].instance 
    mga_iteration = ObjectClass(:mga_iteration, [])
    build_model!(m; log_level)
    t = current_window(m)
    mga_parts = m.ext[:spineopt].expressions[:mga_objective_parts] = init_mga_objective_expressions()
    variable_group_values = iterative_mga!(
        m, 
        m.ext[:spineopt].variables,
        prepare_variable_groups(m),
        mga_iteration,
        something(max_mga_iterations(model=instance), 0),
        mga_parts[(model=instance, t=t)],
        max_mga_slack(model=instance),
        (m) -> total_costs(m, anything),
        (m; iteration) ->  solve_model!(
                m;
                log_level=log_level,
                update_names=update_names,
                output_suffix=_add_mga_iteration(iteration, mga_iteration),
            )
    )
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
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
    variable_group_parameters,
    mga_iteration,
    max_mga_iters,
    mga_weighted_groups,
    mga_slack,
    goal_function::Function,
    solve_wrapper::Function = (m; iteration) -> (optimize!(m); true)
)   
    group_variable_values = Dict()
    hsj_weights = init_hsj_weights()
    solve_wrapper(m; iteration=0)
    group_variable_values[0] = get_variable_group_values(variables, variable_group_parameters)
    update_hsj_weights!(group_variable_values[0], last(mga_iteration()), hsj_weights, variable_group_parameters)
    add_hsj_mga_objective_constraint!(m, mga_slack, goal_function)
    for i=1:max_mga_iters
        update_hsj_mga_objective!(m, hsj_weights, last(mga_iteration()), variables, variable_group_parameters, mga_weighted_groups)
        solve_wrapper(m; iteration=i) || break
        group_variable_values[i] = get_variable_group_values(variables, variable_group_parameters)
        update_hsj_weights!(group_variable_values[i], last(mga_iteration()), hsj_weights, variable_group_parameters)
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

function init_mga_objective_expressions()
    return DefaultDict(() -> DefaultDict(0))
end

function update_hsj_mga_objective!(
    m::Model,
    hsj_weights::AbstractDict,
    iteration,
    variables::AbstractDict,
    group_parameters::AbstractDict,
    mga_weighted_groups::AbstractDict
)
    for (group_name, (available_indices, scenario_weights, mga_indices_func)) in group_parameters
        mga_weighted_groups[group_name] = prepare_objective_hsj_mga(
            m,
            variables[group_name],
            available_indices,
            scenario_weights,
            mga_indices_func(),
            hsj_weights[group_name]
        )
    end
    return @objective(
        m, Min, sum(mga_weighted_groups[mga_group] for mga_group in keys(group_parameters))
    )
end

function prepare_objective_hsj_mga(
    m::Model,
    variable,
    variable_indices::Function,
    variable_stochastic_weights::Function,
    mga_indices::AbstractArray,
    mga_weights::AbstractDict
)   
    weighted_group_variables = (
        get_scenario_variable_average(variable, variable_indices(i), variable_stochastic_weights) * mga_weights[i]
        for i in mga_indices
    )
    return @expression(m, sum(weighted_group_variables, init=0))
end

function get_scenario_variable_average(variable, variable_indices, scenario_weights)
    return sum(variable[i] * scenario_weights(i) for i in variable_indices)
end

function add_hsj_mga_objective_constraint!(m::Model, raw_slack, goal_function)
    slack = slack_correction(raw_slack, objective_value(m))
    return @constraint(m, goal_function(m) <= (1 + slack) * objective_value(m))
end

function slack_correction(raw_slack, objective_value)
    return objective_value >= 0 ? raw_slack : -raw_slack
end

function init_hsj_weights()
    return DefaultDict(() -> DefaultDict(0))
end

function update_hsj_weights!(
    variable_values::AbstractDict,
    mga_current_iteration,
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
    variable_values,
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