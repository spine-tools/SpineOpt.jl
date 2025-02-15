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
    variable_group_parameters = prepare_variable_groups(m)
    max_mga_iters = max_mga_iterations(model=m.ext[:spineopt].instance)
    mga_iteration = ObjectClass(:mga_iteration, [])
    @eval mga_iteration = $mga_iteration
    build_model!(m; log_level)
    solve_model!(
        m;
        log_level=log_level,
        update_names=update_names,
        output_suffix=_add_mga_iteration(0),
    )
    variables = m.ext[:spineopt].variables
    m.ext[:spineopt].expressions[:mga_objective_parts] = init_mga_objective_expressions()
    hsj_weights = init_hsj_weights()
    update_hsj_weights!(get_variable_group_values(variables, variable_group_parameters), last(mga_iteration()), hsj_weights, variable_group_parameters)
    add_hsj_mga_objective_constraint!(m)
    for i=1:max_mga_iters
        update_hsj_mga_objective!(m, hsj_weights, last(mga_iteration()), variable_group_parameters)
        solve_model!(
            m;
            log_level=log_level,
            update_names=update_names,
            output_suffix=_add_mga_iteration(i),
        ) || break
        update_hsj_weights!(get_variable_group_values(variables, variable_group_parameters), last(mga_iteration()), hsj_weights, variable_group_parameters)
    end
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
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
        variable_group => Dict(
            var_idx => value(variables[group_name][var_idx]) for i in mga_indices_func() for var_idx in available_indices(i)
        ) for (group_name, (available_indices, _, mga_indices_func)) in variable_group_parameters
    )
end

function init_mga_objective_expressions()
    return DefaultDict(() -> DefaultDict(0))
end

function update_hsj_mga_objective!(m, hsj_weights, iteration, group_parameters)
    instance = m.ext[:spineopt].instance
    t = current_window(m)
    mga_weighted_groups = m.ext[:spineopt].expressions[:mga_objective_parts][(model=instance, t=t)]
    for (group_name, (available_indices, scenario_weights, mga_indices_func)) in group_parameters
        mga_weighted_groups[variable_name] = prepare_objective_hsj_mga(
            m,
            m.ext[:spineopt].variables[group_name],
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

function add_hsj_mga_objective_constraint!(m::Model)
    instance = m.ext[:spineopt].instance
    slack = slack_correction(max_mga_slack(model=instance), objective_value(m))
    m.ext[:spineopt].constraints[:mga_slack_constraint] = Dict(
        (instance,) => @constraint(m,
            total_costs(m, anything) <= (1 + slack) * objective_value(m)
        )
    )
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
    variable_values::AbstractArray,
    variable_indices::Function,
    variable_hsj_weights::AbstractDict
)
    for i in mga_indices
        if was_variable_active(variable_values, variable_indices(i))
            variable_hsj_weights[i] = 1
        end
    end
end

function was_variable_active(variable_values::AbstractArray, variable_indices::AbstractArray)
    return any(variable_values[i] > 0 for i in variable_indices)
end