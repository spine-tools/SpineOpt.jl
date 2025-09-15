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

"Bridges are required for MGA algorithm"
needs_bridges(::Val{:hsj_mga_algorithm}) = true
needs_bridges(::Val{:fuzzy_mga_algorithm}) = true

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
        algorithm_type,
        (m; iteration) ->  solve_model!(
                m;
                log_level=log_level,
                update_names=update_names,
                output_suffix=_add_mga_iteration(iteration, mga_iteration),
            ) && primal_status(m) == FEASIBLE_POINT,
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

struct VariableGroupParameters
    variable_scenario_indices::Function # returns scenario indices for a given variable
    scenario_weights::Function # weight of the scenario
    variable_indices::AbstractArray # index per single variable, spread across scenarios 
end

function prepare_variable_groups(m::Model)
    return Dict(
        :units_invested  => VariableGroupParameters(
            (ind) -> units_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(unit_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            units_invested_mga_indices()
        ),
        :connections_invested  => VariableGroupParameters(
            (ind) -> connections_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(connection_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            connections_invested_mga_indices(),
        ),
        :storages_invested  => VariableGroupParameters(
            (ind) -> storages_invested_available_indices(m; ind...),
            (stoch_ind) -> realize(node_stochastic_scenario_weight(m; _drop_key(stoch_ind, :t)...)),
            storages_invested_mga_indices(),
        ),
    )
end

"""
    iterative_mga!(m, variables,group_parameters, max_mga_iters, mga_slack, algorithm_type, solve_wrapper) 

Runs the iterative mga process.

# Arguments:
- m::Model - JuMP model
- variables::AbstractDict - dict that returns a dict with scenario variable for an mga group
- group_parameters::AbstractDict - dict of parameters for every mga variable group
- max_mga_iters - no. mga iterations
- mga_slack - slack for near-optimal exploration
- algorithm_type::Val - value for multiple dispatch
- solve_wrapper::Function - wrapper that runs the optimization and returns boolean value with the status
"""
function iterative_mga!(
    m::Model, 
    variables::AbstractDict,
    group_parameters::AbstractDict{Symbol, VariableGroupParameters},
    max_mga_iters,
    mga_slack,
    algorithm_type::Val,
    solve_wrapper::Function = (m; iteration) -> (optimize!(m); true),
)   
    hsj_weights = init_hsj_weights()
    solve_wrapper(m; iteration=0)
    variable_group_values = Dict(0 => get_variable_group_values(variables, group_parameters))
    update_hsj_weights!(variable_group_values[0], hsj_weights, group_parameters, algorithm_type)
    slack = slack_correction(mga_slack, objective_value(m))
    constraint = add_mga_objective_constraint!(m, slack, algorithm_type)
    for i=1:max_mga_iters
        update_mga_objective!(m, hsj_weights, variables, variable_group_values[i-1], group_parameters, constraint, algorithm_type)
        solve_wrapper(m; iteration=i) || break
        variable_group_values[i] = get_variable_group_values(variables, group_parameters)
        update_hsj_weights!(variable_group_values[i], hsj_weights, group_parameters, algorithm_type)
    end
    return variable_group_values
end

"""
    get_variable_group_values(variables, group_parameters)

Retrieves values of mga variables and stores them in the returned dict.

# Arguments
- variables - dict of variable group indexed variables
- group_parameters::Dict{Symbol, VariableGroupParameters} - dict of parameters for every mga variable group
"""
function get_variable_group_values(variables::AbstractDict, group_parameters::AbstractDict{Symbol, VariableGroupParameters})
    return Dict(
        group_name => Dict(
            var_idx => value(variables[group_name][var_idx]) 
            for i in group.variable_indices for var_idx in group.variable_scenario_indices(i)
        ) for (group_name, group) in group_parameters
    )
end

"""
    update_mga_objective!(m, hsj_weights, variables, variable_values, groups_parameters, objective_constraint, algorithm_type)

Reformulates mga objective based on new variable values.

# Arguments:
- m::Model - JuMP model
- hsj_weights::AbstractDict - dict that returns a dict with mga weights per variable for an mga group key
- variables::AbstractDict - dict that returns a dict with scenario variable for an mga group
- variable_values::AbstractDict - dict that returns a dict with scenario variable values for an mga group
- group_parameters::AbstractDict - dict that returns mga params for an mga group
- objective_constraint - objective constraint (can be an expression in case of the fuzzy formulation)
- algorithm_type::Val - value for multiple dispatch
"""
function update_mga_objective!(
    m::Model,
    hsj_weights::AbstractDict,
    variables::AbstractDict,
    variable_values::AbstractDict,
    groups_parameters::AbstractDict{Symbol, VariableGroupParameters},
    objective_constraint,
    algorithm_type::Val
)
    mga_weighted_groups = Dict(
        group_name => prepare_objective_mga!(
            group,
            variables[group_name],
            variable_values[group_name],
            hsj_weights[group_name],
            algorithm_type
        ) for (group_name, group) in groups_parameters
    )
    return formulate_mga_objective!(m, mga_weighted_groups, objective_constraint, algorithm_type)
end

"""
    formulate_mga_objective!(m, mga_weighted_groups, objective_constraint, ::Val{:hsj_mga_algorithm})

Minimizes the sum of all mga group sums

# Arguments
- m::Model - JuMP model
- mga_weighted_groups::AbstractDict - dict with expressions representing each variable group (s_i)
- objective_constraint - objective constraint
- objective_constraint::AbstractDict - dict representing the near optimality constraint

"""
function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    objective_constraint,
    ::Val{:hsj_mga_algorithm}
)
    # we minimize the sum of all variable group weighted sums
    return Dict(
        :heterogeneity_metric => mga_weighted_groups,
        :objective_metric => objective_constraint,
        :objective => @objective(m, Min, sum(values(mga_weighted_groups)))
    )
end

"""
    formulate_mga_objective!(m, mga_weighted_groups, objective_constraint, ::Val{:fuzzy_mga_algorithm}, eps=1e-4)
     
Creates the fuzzy rpm formulation - lexmax (min_i s_i, ∑_i s_i) where s_i is the achievement function for ith objective.

# Arguments
- m::Model - JuMP model
- mga_weighted_groups::AbstractDict - dict with expressions representing each variable group (s_i)
- objective_constraint - representing the near optimality constraint achievement function
- eps - small constant for efficient lexmax implementation
"""
function formulate_mga_objective!(
    m::Model,
    mga_weighted_groups::AbstractDict,
    objective_constraint,
    ::Val{:fuzzy_mga_algorithm},
    eps=1e-4    
)   
    s_min = @variable(m)
    return Dict(
        :variable => s_min,
        :heterogeneity_metric => Dict(
            group_name => @constraint(m, s_min <= group_sum) for (group_name, group_sum) in mga_weighted_groups
        ),
        :objective_metric => @constraint(m, s_min <= objective_constraint),
        :objective => @objective(m, Max, s_min + eps * (sum(values(mga_weighted_groups)) + objective_constraint))
    )
end

"""
    prepare_objective_mga!(group_parameters, variable, variable_values, mga_weights, ::Val{:hsj_mga_algorithm}) 

Creates a weighted mga for variables from a single mga group

# Arguments

- group_parameters::VariableGroupParameters - describes the group parameters of a given variable group
- variable - dict with JuMP scenario variables
- variable_values::AbstractDict - dict with values of variables from previous iteration
- mga_weights::AbstractDict - mga weights from a previous iteration
"""
function prepare_objective_mga!(
    group_parameters::VariableGroupParameters,
    variable,
    variable_values::AbstractDict,
    mga_weights::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)   
    # mga variables with appropriate weights
    weighted_variable_groups = (
        get_scenario_variable_average(variable, group_parameters.variable_scenario_indices(i), group_parameters.scenario_weights) * mga_weights[i]
        for i in group_parameters.variable_indices
    )
    # our objective is a sum of all the mga weighted variables
    return sum(weighted_variable_groups, init=0)
end

"""
    prepare_objective_mga!(group_parameters, variable, variable_values, mga_weights, ::Val{:fuzzy_mga_algorithm}) 

Creates a fuzzy objective for one of the variable groups.

# Arguments
- m::Model - JuMP model
- group_parameters::VariableGroupParameters - describes the group parameters of a given variable group
- variable - dict with JuMP scenario variables
- variable_values::AbstractDict - dict with values of variables from previous iteration
- mga_weights::AbstractDict - mga weights from a previous iteration
"""
function prepare_objective_mga!(
    group_parameters::VariableGroupParameters,
    variable,
    variable_values::AbstractDict,
    mga_weights::AbstractDict,
    ::Val{:fuzzy_mga_algorithm}
)   
    # mga variables with appropriate weights
    weighted_variable_groups = (
        get_scenario_variable_average(variable, group_parameters.variable_scenario_indices(i), group_parameters.scenario_weights) * mga_weights[i]
        for i in group_parameters.variable_indices
    )
    # values of mga expressions in current point
    weighted_variable_group_values = (
        get_scenario_variable_average(variable_values, group_parameters.variable_scenario_indices(i), group_parameters.scenario_weights) * mga_weights[i]
        for i in group_parameters.variable_indices
    )
    a = 0 # we aspire to zero out all of the nonzero variables
    y = sum(weighted_variable_groups, init=0) # mga sum expression
    r = sum(weighted_variable_group_values, init=0) # we start to get satisfied after the point of no change
    # we create an achievement function for every variable group
    return isapprox(a, r) ? 1 : (y-r)/(a-r)
end

"""
    get_scenario_variable_average(variable, variable_indices, scenario_weights)

Gets scenario variables averaged with their weights

# Arguments
- variable - dict of scenario variables
- variable_indices - iterator with indexes for our variable
- scenario_weights - returns the weight of scenario
"""
function get_scenario_variable_average(variable, variable_indices, scenario_weights::Function)
    return sum(variable[i] * scenario_weights(i) for i in variable_indices; init=0)
end

"""
    add_mga_objective_constraint!(m, slack, ::Val{:hsj_mga_algorithm})

Adds a constraint that forces nearly optimal solutions

# Arguments
- m::Model - JuMP model
- slack - how many percents can we stray from the optimal value
"""
function add_mga_objective_constraint!(m::Model, slack, ::Val{:hsj_mga_algorithm})
    return @constraint(m, objective_function(m) <= (1 + slack) * objective_value(m))
end

"""
    add_mga_objective_constraint!(m, slack, ::Val{:fuzzy_mga_algorithm})

Adds constraints used by the Reference Point Method.

# Arguments
- m::Model - JuMP model
- slack - the mga slack
"""
function add_mga_objective_constraint!(m::Model, slack, ::Val{:fuzzy_mga_algorithm})
    y = objective_function(m)
    a = objective_value(m) # we aspire to reach the best possible value
    r = (1 + slack) * objective_value(m) # we start to get satsfied when reaching nearly optimal solution
    if isapprox(a, r)
        @constraint(m, y == a)
        return 1
    else
        return (y-r)/(a-r)
    end
end

"""
    slack_correction(raw_slack, objective_value) 

If the objective value was negative, the f(x) <= (1+slack) * f(x_optim_ would be infeasible unless we negate the value of slack
"""
slack_correction(raw_slack, objective_value) = objective_value >= 0 ? raw_slack : -raw_slack

init_hsj_weights() = DefaultDict{Symbol, AbstractDict}(() -> DefaultDict(0))

"""
    update_hsj_weights!(variable_values, variable_hsj_weights, groups_parameters, algorithm_type)

Updates the weights in the passed dict according to the Hop Skip Jump scheme, in all mga groups

# Arguments
- variable_values::AbstractDict{Symbol, AbstractDict} - dict of all variable_values from previous iteration
- variable_hsj_weights::AbstractDict{Symbol, AbstractDict} - dict of all mga weights
- group_parameters::AbstractDict{Symbol, VariableGroupParameters} - dict of all group parameters
"""
function update_hsj_weights!(
    variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict{Symbol, AbstractDict},
    groups_parameters::AbstractDict{Symbol, VariableGroupParameters},
    algorithm_type::Val
)
    for (group_name, group) in groups_parameters
        do_update_hsj_weights!(
            group,
            variable_values[group_name],
            variable_hsj_weights[group_name],
            algorithm_type
        )
    end
end

"""    
    do_update_hsj_weights!(group, all_variable_values, variable_hsj_weights, ::Val{:hsj_mga_algorithm})

Updates the weights in the passed dict according to the Hop Skip Jump scheme.
Variables that were nonzero in a iteration before have their weights set to 1. Previous weights aren't cleared.

# Arguments
- group_parameters::VariableGroupParameters - describes the group parameters of a given variable group
- all_variable_values::AbstractDict - dict of all variable scenario values from a single group, from previous iteration
- variable_scenario_indices::Function - returns all stochastic indices for a single variable
- variable_hsj_weights::AbstractDict - dict of mga weights to be updated
"""
function do_update_hsj_weights!(
    group::VariableGroupParameters,
    all_variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict,
    ::Val{:hsj_mga_algorithm}
)
    active_variables = filter(i -> was_variable_active(all_variable_values, group.variable_scenario_indices(i)), group.variable_indices)
    for i in active_variables
        variable_hsj_weights[i] = 1
    end

end

"""    
    do_update_hsj_weights!(group, all_variable_values, variable_hsj_weights, ::Val{:fuzzy_mga_algorithm})

Updates the weights in the passed dict according to the Hop Skip Jump scheme.
Variables that were nonzero in a iteration before have their weights set to 1/value to foster exploration. Previous weights aren't cleared.

# Arguments
- group_parameters::VariableGroupParameters - describes the group parameters of a given variable group
- all_variable_values::AbstractDict - dict of all variable scenario values from a single group, from previous iteration
- variable_scenario_indices::Function - returns all stochastic indices for a single variable
- variable_hsj_weights::AbstractDict - dict of mga weights to be updated
"""
function do_update_hsj_weights!(
    group::VariableGroupParameters,
    all_variable_values::AbstractDict,
    variable_hsj_weights::AbstractDict,
    ::Val{:fuzzy_mga_algorithm}
)
    active_variables = filter(i -> was_variable_active(all_variable_values, group.variable_scenario_indices(i)), group.variable_indices)
    for i in active_variables
        variable_value = get_scenario_variable_average(all_variable_values, group.variable_scenario_indices(i), group.scenario_weights)
        variable_hsj_weights[i] = 1 / variable_value
    end
end

"""
    was_variable_active(all_variable_values, variable_indices)

Checks if variable was nonzero in any of the scenarios.

# Arguments
- all_variable_values::AbstractDict - dict of all variable scenario values from a single group, from previous iteration
- variable_indices - iterator or array with stochastic indices for a single variable
"""
function was_variable_active(all_variable_values::AbstractDict, variable_indices)
    return any(all_variable_values[i] > 0 for i in variable_indices)
end
