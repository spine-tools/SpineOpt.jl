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
    ::Val{:fuzzy_mga_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
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
    variable_group_parameters = Dict(
        :units_invested  => (
            units_invested_available_indices,
            unit_stochastic_scenario_weight,
            units_invested_mga_indices,
        ),
        :connections_invested  => (
            connections_invested_available_indices,
            connection_stochastic_scenario_weight,
            connections_invested_mga_indices,
        ),
        :storages_invested  => (
            storages_invested_available_indices,
            node_stochastic_scenario_weight,
            storages_invested_mga_indices,
        ),
    )
    variable_groups = keys(variable_group_parameters)
    hsj_weights = update_hsj_weights!(m, last(mga_iteration()), nothing, variable_group_parameters)
    add_fuzzy_mga_objective_constraint!(m)
    for i=1:max_mga_iters
        prepare_objective_fuzzy_mga!(m, hsj_weights, last(mga_iteration()), variable_group_parameters)
        set_fuzzy_mga_objective!(m, variable_groups)
        solve_model!(
            m;
            log_level=log_level,
            update_names=update_names,
            output_suffix=_add_mga_iteration(i),
        ) || break
        update_hsj_weights!(m, last(mga_iteration()), hsj_weights, variable_group_parameters)
    end
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
end

function prepare_objective_fuzzy_mga!(m, hsj_weights, iteration, group_parameters)
    for (group_name, (available_indices, scenario_weights, mga_indices)) in group_parameters
        do_prepare_objective_fuzzy_mga!(
            m,
            group_name,
            available_indices,
            scenario_weights,
            mga_indices,
            hsj_weights[group_name],
            iteration
        )
    end
end

function do_prepare_objective_fuzzy_mga!(
    m::Model,
    variable_name::Symbol,
    variable_indices_function::Function,
    scenario_weight_function::Function,
    mga_indices::Function,
    iter_weights::DefaultDict,
    mga_current_iteration::Object
)   
    instance = m.ext[:spineopt].instance
    t = current_window(m)
    objective_variables = get!(m.ext[:spineopt].expressions, :mga_objective, Dict())
    weighted_mga_variables = get!(objective_variables, (model=instance, t=t), Dict())
    @fetch units_invested = m.ext[:spineopt].variables
    if !isempty(mga_indices())
        weighted_mga_variables[variable_name] = @expression(
            m,
            sum(
                get_scenario_variable_average(m, variable_name, ind, variable_indices_function, scenario_weight_function) * iter_weights[(variable_name, ind)]
                for ind in mga_indices()
            )        
        )
    end
end

function add_fuzzy_mga_objective_constraint!(m::Model)
    instance = m.ext[:spineopt].instance
    slack = objective_value(m) >= 0 ? max_mga_slack(model=instance) : -max_mga_slack(model=instance)
    m.ext[:spineopt].constraints[:mga_slack_constraint] = Dict(
        (instance,) => @constraint(m,
            total_costs(m, anything) <= (1 + slack) * objective_value(m)
        )
    )
end

function set_fuzzy_mga_objective!(m, variable_groups)
    instance = model=m.ext[:spineopt].instance
    t = current_window(m)
    weighted_mga_variables = m.ext[:spineopt].expressions[:mga_objective][(model=instance, t=t)]
    @objective(
        m,
        Min,
        sum(
            get(weighted_mga_variables, mga_group, 0) for mga_group in variable_groups
        )
    )
end

function get_scenario_variable_average(
    m::Model,
    variable_name::Symbol,
    variable_indicator,
    variable_indices_function::Function,
    scenario_weight_function::Function
)
    variable = m.ext[:spineopt].variables[variable_name]
    return sum(
        variable[ind] * scenario_weight_function(m; _drop_key(ind, :t)...)
        for ind in variable_indices_function(m; variable_indicator...)
    )
end

function was_variable_active(
    m::Model,
    variable_name::Symbol,
    variable_indices_function::Function,
    variable_indicator
)
    variable = m.ext[:spineopt].variables[variable_name]
    return any(
        value(variable[ind]) > 0
        for ind in variable_indices_function(m; variable_indicator...)
    )
end

function update_hsj_weights!(
    m::Model,
    mga_current_iteration,
    variable_hsj_weights,
    group_parameters
)
    if isnothing(variable_hsj_weights)
        variable_hsj_weights = Dict(
            group => DefaultDict(0) for group in keys(group_parameters)
        )
    end
    for (group_name, (available_indices, _, mga_indices)) in group_parameters
        do_update_hsj_weights!(
            m,
            group_name,
            available_indices,
            mga_indices,
            mga_current_iteration,
            variable_hsj_weights[group_name],
        )
    end
    return variable_hsj_weights
end

function do_update_hsj_weights!(
    m::Model,
    variable_name::Symbol,
    variable_indices_function::Function,
    mga_indices::Function,
    mga_current_iteration::Object,
    variable_hsj_weights::DefaultDict
)
    for ind in mga_indices()
        if was_variable_active(m, variable_name, variable_indices_function, ind)
            variable_hsj_weights[variable_name, ind] = 1
        end
    end
end