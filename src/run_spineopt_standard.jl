#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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

function rerun_spineopt!(
    m::Model,
    ::Nothing,
    ::Nothing,
    url_out::Union{String,Nothing};
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    alternative_objective=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false
)
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Creating economic structure..." generate_economic_structure!(m)
    init_model!(
        m;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        log_level=log_level,
        alternative_objective=alternative_objective
    )
    init_outputs!(m)
    k = 1
    calculate_duals = any(startswith(lowercase(name), r"bound_|constraint_") for name in String.(keys(m.ext[:outputs])))
    while optimize
        @log log_level 1 "Window $k: $(current_window(m))"
        optimize_model!(m; log_level=log_level, calculate_duals=calculate_duals) || break
        @timelog log_level 2 "Post-processing results..." postprocess_results!(m)
        @timelog log_level 2 "Fixing non-anticipativity values..." fix_non_anticipativity_values!(m)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
        k += 1
    end
    @timelog log_level 2 "Writing report..." write_report(m, url_out)
    m
end

"""
Add SpineOpt variables to the given model.
"""
function add_variables!(m; add_user_variables=m -> nothing, log_level=3)
    @timelog log_level 3 "- [variable_units_available]" add_variable_units_available!(m)
    @timelog log_level 3 "- [variable_units_on]" add_variable_units_on!(m)
    @timelog log_level 3 "- [variable_units_started_up]" add_variable_units_started_up!(m)
    @timelog log_level 3 "- [variable_units_shut_down]" add_variable_units_shut_down!(m)
    @timelog log_level 3 "- [variable_unit_flow]" add_variable_unit_flow!(m)
    @timelog log_level 3 "- [variable_unit_flow_op]" add_variable_unit_flow_op!(m)
    @timelog log_level 3 "- [variable_connection_flow]" add_variable_connection_flow!(m)
    @timelog log_level 3 "- [variable_connection_intact_flow]" add_variable_connection_intact_flow!(m)
    @timelog log_level 3 "- [variable_connections_invested]" add_variable_connections_invested!(m)
    @timelog log_level 3 "- [variable_connections_invested_available]" add_variable_connections_invested_available!(m)
    @timelog log_level 3 "- [variable_connections_invested_available_vintage]" add_variable_connections_invested_available_vintage!(m)
    @timelog log_level 3 "- [variable_connections_decommissioned]" add_variable_connections_decommissioned!(m)
    @timelog log_level 3 "- [variable_connections_decommissioned_vintage]" add_variable_connections_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_connections_early_decommissioned_vintage]" add_variable_connections_early_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_storages_invested]" add_variable_storages_invested!(m)
    @timelog log_level 3 "- [variable_storages_invested_available]" add_variable_storages_invested_available!(m)
    @timelog log_level 3 "- [variable_storages_invested_available_vintage]" add_variable_storages_invested_available_vintage!(m)
    @timelog log_level 3 "- [variable_storages_invested_state]" add_variable_storages_invested_state!(m)
    @timelog log_level 3 "- [variable_storages_invested_state_vintage]" add_variable_storages_invested_state_vintage!(m)
    @timelog log_level 3 "- [variable_storages_decommissioned]" add_variable_storages_decommissioned!(m)
    @timelog log_level 3 "- [variable_storages_decommissioned_vintage]" add_variable_storages_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_storages_mothballed_state_vintage]" add_variable_storages_mothballed_state_vintage!(m)
    @timelog log_level 3 "- [variable_storages_mothballed_vintage]" add_variable_storages_mothballed_vintage!(m)
    @timelog log_level 3 "- [variable_storages_demothballed_vintage]" add_variable_storages_demothballed_vintage!(m)
    @timelog log_level 3 "- [variable_storages_early_decommissioned_vintage]" add_variable_storages_early_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_node_state]" add_variable_node_state!(m)
    @timelog log_level 3 "- [variable_node_slack_pos]" add_variable_node_slack_pos!(m)
    @timelog log_level 3 "- [variable_node_slack_neg]" add_variable_node_slack_neg!(m)
    @timelog log_level 3 "- [variable_node_injection]" add_variable_node_injection!(m)
    @timelog log_level 3 "- [variable_units_invested]" add_variable_units_invested!(m)
    @timelog log_level 3 "- [variable_units_invested_available]" add_variable_units_invested_available!(m)
    @timelog log_level 3 "- [variable_units_invested_available_vintage]" add_variable_units_invested_available_vintage!(m)
    @timelog log_level 3 "- [variable_units_invested_state]" add_variable_units_invested_state!(m)
    @timelog log_level 3 "- [variable_units_invested_state_vintage]" add_variable_units_invested_state_vintage!(m)
    @timelog log_level 3 "- [variable_units_decommissioned]" add_variable_units_decommissioned!(m)
    @timelog log_level 3 "- [variable_units_decommissioned_vintage]" add_variable_units_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_units_mothballed_state_vintage]" add_variable_units_mothballed_state_vintage!(m)
    @timelog log_level 3 "- [variable_units_mothballed_vintage]" add_variable_units_mothballed_vintage!(m)
    @timelog log_level 3 "- [variable_units_demothballed_vintage]" add_variable_units_demothballed_vintage!(m)
    @timelog log_level 3 "- [variable_units_early_decommissioned_vintage]" add_variable_units_early_decommissioned_vintage!(m)
    @timelog log_level 3 "- [variable_ramp_up_unit_flow]" add_variable_ramp_up_unit_flow!(m)
    @timelog log_level 3 "- [variable_start_up_unit_flow]" add_variable_start_up_unit_flow!(m)
    @timelog log_level 3 "- [variable_nonspin_units_started_up]" add_variable_nonspin_units_started_up!(m)
    @timelog log_level 3 "- [variable_nonspin_ramp_up_unit_flow]" add_variable_nonspin_ramp_up_unit_flow!(m)
    @timelog log_level 3 "- [variable_ramp_down_unit_flow]" add_variable_ramp_down_unit_flow!(m)
    @timelog log_level 3 "- [variable_shut_down_unit_flow]" add_variable_shut_down_unit_flow!(m)
    @timelog log_level 3 "- [variable_nonspin_units_shut_down]" add_variable_nonspin_units_shut_down!(m)
    @timelog log_level 3 "- [variable_nonspin_ramp_down_unit_flow]" add_variable_nonspin_ramp_down_unit_flow!(m)
    @timelog log_level 3 "- [variable_node_pressure]" add_variable_node_pressure!(m)
    @timelog log_level 3 "- [variable_node_voltage_angle]" add_variable_node_voltage_angle!(m)
    @timelog log_level 3 "- [variable_binary_gas_connection_flow]" add_variable_binary_gas_connection_flow!(m)
    @timelog log_level 3 "- [user_defined_variables]" add_user_variables(m)
end

"""
Fix a variable to the values specified by the `fix_value` parameter function, if any.
"""
_fix_variable!(m::Model, name::Symbol, indices::Function, fix_value::Nothing) = nothing
function _fix_variable!(m::Model, name::Symbol, indices::Function, fix_value::Function)
    var = m.ext[:variables][name]
    bin = m.ext[:variables_definition][name][:bin]
    int = m.ext[:variables_definition][name][:int]
    for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
        fix_value_ = _apply_function_or_nothing(fix_value, ind)
        fix_value_ != nothing && !isnan(fix_value_) && fix(var[ind], fix_value_; force=true)
    end
end

"""
Fix all variables in the given model to the values computed by the corresponding `fix_value` parameter function, if any.
"""
function fix_variables!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        _fix_variable!(m, name, definition[:indices], definition[:fix_value])
    end
end

function _update_variable!(m::Model, name::Symbol, definition::Dict)
    var = m.ext[:variables][name]
    val = m.ext[:values][name]
    indices = definition[:indices]
    lb = definition[:lb]
    ub = definition[:ub]
    for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
        if is_fixed(var[ind])
            unfix(var[ind])
            lb != nothing && set_lower_bound(var[ind], lb(ind))
            ub != nothing && set_upper_bound(var[ind], ub(ind))
        end
        history_t = t_history_t(m; t=ind.t)
        history_t === nothing && continue
        for history_ind in indices(m; ind..., t=history_t)
            fix(var[history_ind], val[ind]; force=true)
        end
    end
end

function update_variables!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        _update_variable!(m, name, definition)
    end
end

function _fix_non_anticipativity_value!(m, name::Symbol, definition::Dict)
    var = m.ext[:variables][name]
    val = m.ext[:values][name]
    indices = definition[:indices]
    non_anticipativity_time = definition[:non_anticipativity_time]
    window_start = start(current_window(m))
    for ind in indices(m; t=time_slice(m))
        non_anticipativity_time_ = _apply_function_or_nothing(non_anticipativity_time, ind)
        if non_anticipativity_time_ != nothing && start(ind.t) < window_start +  non_anticipativity_time_
            fix(var[ind], val[ind]; force=true)
        end
    end
end

function fix_non_anticipativity_values!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        _fix_non_anticipativity_value!(m, name, definition)
    end
end

"""
Add SpineOpt constraints to the given model.
"""
function add_constraints!(m; add_constraints=m -> nothing, log_level=3)
    @timelog log_level 3 "- [constraint_unit_pw_heat_rate]" add_constraint_unit_pw_heat_rate!(m)
    @timelog log_level 3 "- [constraint_user_constraint]" add_constraint_user_constraint!(m)
    @timelog log_level 3 "- [constraint_node_injection]" add_constraint_node_injection!(m)
    @timelog log_level 3 "- [constraint_nodal_balance]" add_constraint_nodal_balance!(m)
    @timelog log_level 3 "- [constraint_candidate_connection_flow_ub]" add_constraint_candidate_connection_flow_ub!(m)
    @timelog log_level 3 "- [constraint_candidate_connection_flow_lb]" add_constraint_candidate_connection_flow_lb!(m)
    @timelog log_level 3 "- [constraint_connection_intact_flow_ptdf]" add_constraint_connection_intact_flow_ptdf!(m)
    @timelog log_level 3 "- [constraint_connection_flow_intact_flow]" add_constraint_connection_flow_intact_flow!(m)
    @timelog log_level 3 "- [constraint_connection_flow_lodf]" add_constraint_connection_flow_lodf!(m)
    @timelog log_level 3 "- [constraint_connection_flow_capacity]" add_constraint_connection_flow_capacity!(m)
    @timelog log_level 3 "- [constraint_connection_intact_flow_capacity]" add_constraint_connection_intact_flow_capacity!(m)
    @timelog log_level 3 "- [constraint_unit_flow_capacity]" add_constraint_unit_flow_capacity!(m)
    @timelog log_level 3 "- [constraint_connections_invested_available]" add_constraint_connections_invested_available!(m)
    @timelog log_level 3 "- [constraint_connections_invested_available_vintage" add_constraint_connections_invested_available_vintage!(m)
    @timelog log_level 3 "- [constraint_connections_invested_available_bound]" add_constraint_connections_invested_available_bound!(m)
    @timelog log_level 3 "- [constraint_connections_decommissioned]" add_constraint_connections_decommissioned!(m)
    @timelog log_level 3 "- [constraint_connections_decommissioned_vintage]" add_constraint_connections_decommissioned_vintage!(m)
    @timelog log_level 3 "- [constraint_storages_invested_available]" add_constraint_storages_invested_available!(m)
    @timelog log_level 3 "- [constraint_storages_invested_available_vintage" add_constraint_storages_invested_available_vintage!(m)
    @timelog log_level 3 "- [constraint_storages_invested_available_bound]" add_constraint_storages_invested_available_bound!(m)
    @timelog log_level 3 "- [constraint_storages_invested_state]" add_constraint_storages_invested_state!(m)
    @timelog log_level 3 "- [constraint_storages_invested_state_vintage]" add_constraint_storages_invested_state_vintage!(m)
    @timelog log_level 3 "- [constraint_storages_decommissioned]" add_constraint_storages_decommissioned!(m)
    @timelog log_level 3 "- [constraint_storages_decommissioned_vintage]" add_constraint_storages_decommissioned_vintage!(m)
    @timelog log_level 3 "- [constraint_storages_mothballed_state_vintage]" add_constraint_storages_mothballed_state_vintage!(m)
    @timelog log_level 3 "- [constraint_operating_point_bounds]" add_constraint_operating_point_bounds!(m)
    @timelog log_level 3 "- [constraint_operating_point_sum]" add_constraint_operating_point_sum!(m)
    @timelog log_level 3 "- [constraint_fix_ratio_out_in_unit_flow]" add_constraint_fix_ratio_out_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_max_ratio_out_in_unit_flow]" add_constraint_max_ratio_out_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_min_ratio_out_in_unit_flow]" add_constraint_min_ratio_out_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_fix_ratio_out_out_unit_flow]" add_constraint_fix_ratio_out_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_max_ratio_out_out_unit_flow]" add_constraint_max_ratio_out_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_min_ratio_out_out_unit_flow]" add_constraint_min_ratio_out_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_fix_ratio_in_in_unit_flow]" add_constraint_fix_ratio_in_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_max_ratio_in_in_unit_flow]" add_constraint_max_ratio_in_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_min_ratio_in_in_unit_flow]" add_constraint_min_ratio_in_in_unit_flow!(m)
    @timelog log_level 3 "- [constraint_fix_ratio_in_out_unit_flow]" add_constraint_fix_ratio_in_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_max_ratio_in_out_unit_flow]" add_constraint_max_ratio_in_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_min_ratio_in_out_unit_flow]" add_constraint_min_ratio_in_out_unit_flow!(m)
    @timelog log_level 3 "- [constraint_ratio_out_in_connection_intact_flow]" add_constraint_ratio_out_in_connection_intact_flow!(m)
    @timelog log_level 3 "- [constraint_fix_ratio_out_in_connection_flow]" add_constraint_fix_ratio_out_in_connection_flow!(m)
    @timelog log_level 3 "- [constraint_max_ratio_out_in_connection_flow]" add_constraint_max_ratio_out_in_connection_flow!(m)
    @timelog log_level 3 "- [constraint_min_ratio_out_in_connection_flow]" add_constraint_min_ratio_out_in_connection_flow!(m)
    @timelog log_level 3 "- [constraint_node_state_capacity]" add_constraint_node_state_capacity!(m)
    @timelog log_level 3 "- [constraint_cyclic_node_state]" add_constraint_cyclic_node_state!(m)
    @timelog log_level 3 "- [constraint_max_total_cumulated_unit_flow_from_node]" add_constraint_max_total_cumulated_unit_flow_from_node!(m)
    @timelog log_level 3 "- [constraint_min_total_cumulated_unit_flow_from_node]" add_constraint_min_total_cumulated_unit_flow_from_node!(m)
    @timelog log_level 3 "- [constraint_max_total_cumulated_unit_flow_to_node]" add_constraint_max_total_cumulated_unit_flow_to_node!(m)
    @timelog log_level 3 "- [constraint_min_total_cumulated_unit_flow_to_node]" add_constraint_min_total_cumulated_unit_flow_to_node!(m)
    @timelog log_level 3 "- [constraint_units_on]" add_constraint_units_on!(m)
    @timelog log_level 3 "- [constraint_units_available]" add_constraint_units_available!(m)
    @timelog log_level 3 "- [constraint_units_invested_available]" add_constraint_units_invested_available!(m)
    @timelog log_level 3 "- [constraint_units_invested_available_vintage" add_constraint_units_invested_available_vintage!(m)
    @timelog log_level 3 "- [constraint_units_invested_available_bound]" add_constraint_units_invested_available_bound!(m)
    @timelog log_level 3 "- [constraint_units_invested_state]" add_constraint_units_invested_state!(m)
    @timelog log_level 3 "- [constraint_units_invested_state_vintage]" add_constraint_units_invested_state_vintage!(m)
    @timelog log_level 3 "- [constraint_units_decommissioned]" add_constraint_units_decommissioned!(m)
    @timelog log_level 3 "- [constraint_units_decommissioned_vintage]" add_constraint_units_decommissioned_vintage!(m)
    @timelog log_level 3 "- [constraint_units_mothballed_state_vintage]" add_constraint_units_mothballed_state_vintage!(m)
    @timelog log_level 3 "- [constraint_minimum_operating_point]" add_constraint_minimum_operating_point!(m)
    @timelog log_level 3 "- [constraint_min_down_time]" add_constraint_min_down_time!(m)
    @timelog log_level 3 "- [constraint_min_up_time]" add_constraint_min_up_time!(m)
    @timelog log_level 3 "- [constraint_unit_state_transition]" add_constraint_unit_state_transition!(m)
    @timelog log_level 3 "- [constraint_unit_flow_capacity_w_ramp]" add_constraint_unit_flow_capacity_w_ramp!(m)
    @timelog log_level 3 "- [constraint_split_ramps]" add_constraint_split_ramps!(m)
    @timelog log_level 3 "- [constraint_ramp_up]" add_constraint_ramp_up!(m)
    @timelog log_level 3 "- [constraint_max_start_up_ramp]" add_constraint_max_start_up_ramp!(m)
    @timelog log_level 3 "- [constraint_min_start_up_ramp]" add_constraint_min_start_up_ramp!(m)
    @timelog log_level 3 "- [constraint_max_nonspin_ramp_up]" add_constraint_max_nonspin_ramp_up!(m)
    @timelog log_level 3 "- [constraint_min_nonspin_ramp_up]" add_constraint_min_nonspin_ramp_up!(m)
    @timelog log_level 3 "- [constraint_ramp_down]" add_constraint_ramp_down!(m)
    @timelog log_level 3 "- [constraint_max_shut_down_ramp]" add_constraint_max_shut_down_ramp!(m)
    @timelog log_level 3 "- [constraint_min_shut_down_ramp]" add_constraint_min_shut_down_ramp!(m)
    @timelog log_level 3 "- [constraint_max_nonspin_ramp_down]" add_constraint_max_nonspin_ramp_down!(m)
    @timelog log_level 3 "- [constraint_min_nonspin_ramp_down]" add_constraint_min_nonspin_ramp_down!(m)
    @timelog log_level 3 "- [constraint_res_minimum_node_state]" add_constraint_res_minimum_node_state!(m)
    @timelog log_level 3 "- [constraint_fix_node_pressure_point]" add_constraint_fix_node_pressure_point!(m)
    @timelog log_level 3 "- [constraint_connection_unitary_gas_flow]" add_constraint_connection_unitary_gas_flow!(m)
    @timelog log_level 3 "- [constraint_compression_ratio]" add_constraint_compression_ratio!(m)
    @timelog log_level 3 "- [constraint_storage_line_pack]" add_constraint_storage_line_pack!(m)
    @timelog log_level 3 "- [constraint_connection_flow_gas_capacity]" add_constraint_connection_flow_gas_capacity!(m)
    @timelog log_level 3 "- [constraint_max_node_pressure]" add_constraint_max_node_pressure!(m)
    @timelog log_level 3 "- [constraint_min_node_pressure]" add_constraint_min_node_pressure!(m)
    @timelog log_level 3 "- [constraint_node_voltage_angle]" add_constraint_node_voltage_angle!(m)
    @timelog log_level 3 "- [constraint_max_node_voltage_angle]" add_constraint_max_node_voltage_angle!(m)
    @timelog log_level 3 "- [constraint_min_node_voltage_angle]" add_constraint_min_node_voltage_angle!(m)
    @timelog log_level 3 "- [constraint_user]" add_constraints(m)
    _update_constraint_names!(m)
end

function init_outputs!(m::Model)
    for r in model__report(model=m.ext[:instance])
        for o in report__output(report=r)
            get!(m.ext[:outputs], o.name, Dict{NamedTuple,Dict}())
        end
    end
end

"""
Initialize the given model for SpineOpt: add variables, fix the necessary variables, add constraints and set objective.
"""
function init_model!(
    m; add_user_variables=m -> nothing, add_constraints=m -> nothing, log_level=3, alternative_objective=m -> nothing
)
    @timelog log_level 2 "Adding variables...\n" add_variables!(
        m; add_user_variables=add_user_variables, log_level=log_level
    )
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Adding constraints...\n" add_constraints!(
        m; add_constraints=add_constraints, log_level=log_level
    )
    @timelog log_level 2 "Setting objective..." set_objective!(m;alternative_objective=alternative_objective)
end

"""
Optimize the given model.
If an optimal solution is found, save results and return `true`, otherwise return `false`.
"""
function optimize_model!(m::Model; log_level=3, calculate_duals=false, iterations=nothing)
    write_mps_file(model=m.ext[:instance]) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section.
    @timelog log_level 0 "Optimizing model $(m.ext[:instance])..." optimize!(m)
    if termination_status(m) == MOI.OPTIMAL || termination_status(m) == MOI.TIME_LIMIT
        mip_solver = m.ext[:mip_solver]
        lp_solver = m.ext[:lp_solver]
        if calculate_duals
            @log log_level 1 "Setting up final LP of $(m.ext[:instance]) to obtain duals..."
            @timelog log_level 1 "Fixing integer variables..." relax_integer_vars(m)
            if lp_solver != mip_solver
                @timelog log_level 1 "Switching to LP solver $(lp_solver)..." set_optimizer(m, lp_solver)
            end
            @timelog log_level 1 "Optimizing final LP..." optimize!(m)
            save_marginal_values!(m)
            save_bound_marginal_values!(m)
        end
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving $(m.ext[:instance]) results..." save_model_results!(m,iterations=iterations)
        if calculate_duals
            if lp_solver != mip_solver
                @timelog log_level 1 "Switching back to MIP solver $(mip_solver)..." set_optimizer(m, mip_solver)
            end
            @timelog log_level 1 "Unfixing integer variables..." unrelax_integer_vars(m)
        end
        true
    else
        @log log_level 0 "Unable to find solution (reason: $(termination_status(m)))"
        write_mps_file(model=m.ext[:instance]) == :write_mps_on_no_solve && write_to_file(m, "model_diagnostics.mps")
        false
    end
end

"""
The value of a JuMP variable, rounded if necessary.
"""
_variable_value(v::VariableRef) = (is_integer(v) || is_binary(v)) ? round(Int, JuMP.value(v)) : JuMP.value(v)

"""
Save the value of a variable in a model.
"""
function _save_variable_value!(m::Model, name::Symbol, indices::Function)
    var = m.ext[:variables][name]
    m.ext[:values][name] = Dict(
        ind => _variable_value(var[ind])
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)), temporal_block=anything)
    )
end

"""
Save the value of all variables in a model.
"""
function save_variable_values!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        _save_variable_value!(m, name, definition[:indices])
    end
end

_value(v::GenericAffExpr) = JuMP.value(v)
_value(v) = v

"""
Save the value of the objective terms in a model.
"""
function save_objective_values!(m::Model)
    ind = (model=m.ext[:instance], t=current_window(m))
    for name in [objective_terms(m); :total_costs]
        func = eval(name)
        m.ext[:values][name] = Dict(ind => _value(realize(func(m, end_(ind.t)))))
    end
end

function _value_by_entity_non_aggregated(m, value::Dict)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for (k, v) in value
        end_(k.t) <= analysis_time && continue
        entity = _drop_key(k, :t)
        by_analysis_time_non_aggr = get!(by_entity_non_aggr, entity, Dict{DateTime,Any}())
        by_time_slice_non_aggr = get!(by_analysis_time_non_aggr, analysis_time, Dict{TimeSlice,Any}())
        by_time_slice_non_aggr[k.t] = v
    end
    by_entity_non_aggr
end

function _value_by_entity_non_aggregated(m, parameter::Parameter)
    by_entity_non_aggr = Dict()
    for entity in indices_as_tuples(parameter)
        for (scen, t) in stochastic_time_indices(m)
            entity = (; entity..., stochastic_scenario=scen)
            val = parameter(; entity..., t=t, _strict=false)
            val === nothing && continue
            by_analysis_time_non_aggr = get!(by_entity_non_aggr, entity, Dict{DateTime,Any}())
            by_time_slice_non_aggr = get!(by_analysis_time_non_aggr, start(current_window(m)), Dict{TimeSlice,Any}())
            by_time_slice_non_aggr[t] = val
        end
    end
    by_entity_non_aggr
end

function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, output_time_slices::Array)
    by_time_stamp_aggr = Dict()
    for t_aggr in output_time_slices
        time_slices = filter(t -> iscontained(t, t_aggr), keys(by_time_slice_non_aggr))
        isempty(time_slices) && continue  # No aggregation possible
        by_time_stamp_aggr[start(t_aggr)] = SpineInterface.mean(by_time_slice_non_aggr[t] for t in time_slices)
    end
    by_time_stamp_aggr
end
function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, ::Nothing)
    Dict(start(t) => v for (t, v) in by_time_slice_non_aggr)
end

function _save_output!(m, out, value_or_param; iterations=nothing)
    by_entity_non_aggr = _value_by_entity_non_aggregated(m, value_or_param)
    for (entity, by_analysis_time_non_aggr) in by_entity_non_aggr
        if !isnothing(iterations)
            # FIXME: Needs to be done, befooooore we execute solve, as we need to set objective for this solve
            new_mga_name = Symbol(string("mga_it_", iterations))
            if mga_iteration(new_mga_name) == nothing
                new_mga_i = Object(new_mga_name)
                add_object!(mga_iteration, new_mga_i)
            else
                new_mga_i = mga_iteration(new_mga_name)
            end
            entity = (; entity..., mga_iteration=new_mga_i)
        end
        for (analysis_time, by_time_slice_non_aggr) in by_analysis_time_non_aggr
            t_highest_resolution!(by_time_slice_non_aggr)
            output_time_slices_ = output_time_slices(m, output=out)
            by_time_stamp_aggr = _value_by_time_stamp_aggregated(by_time_slice_non_aggr, output_time_slices_)
            isempty(by_time_stamp_aggr) && continue
            by_entity = get!(m.ext[:outputs], out.name, Dict{NamedTuple,Dict}())
            by_analysis_time = get!(by_entity, entity, Dict{DateTime,Any}())
            by_time_stamp = get!(by_analysis_time, analysis_time, Dict{DateTime,Any}())
            merge!(by_time_stamp, by_time_stamp_aggr)
        end
    end
    true
end
_save_output!(m, out, ::Nothing; iterations=iterations) = false

"""
Save the outputs of a model into a dictionary.
"""
function save_outputs!(m; iterations=nothing)
    for r in model__report(model=m.ext[:instance]), out in report__output(report=r)
        value = get(m.ext[:values], out.name, nothing)
        if _save_output!(m, out, value; iterations=iterations)
            continue
        end
        param = parameter(out.name, @__MODULE__)
        if _save_output!(m, out, param; iterations=iterations)
            continue
        end
        @warn "can't find any values for '$(out.name)'"
    end
end

"""
Save a model results: first postprocess results, then save variables and objective values, and finally save outputs
"""
function save_model_results!(m; iterations=nothing)
    save_variable_values!(m)
    save_objective_values!(m)
    save_outputs!(m; iterations=iterations)
end

"""
Update the given model for the next window in the rolling horizon: update variables, fix the necessary variables,
update constraints and update objective.
"""
function update_model!(m; update_constraints=m -> nothing, log_level=3, update_names=false)
    if update_names
        _update_variable_names!(m)
        _update_constraint_names!(m)
    end
    @timelog log_level 2 "Updating variables..." update_variables!(m)
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Updating constraints..." update_varying_constraints!(m)
    @timelog log_level 2 "Updating user constraints..." update_constraints(m)
    @timelog log_level 2 "Updating objective..." update_varying_objective!(m)
end

function _update_constraint_names!(m)
    for (con_key, cons) in m.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key, inds))
        end
    end
end

function _update_variable_names!(m)
    for (var_key, vars) in m.ext[:variables]
        for (inds, var) in vars
            set_name(var, _base_name(var_key, inds))
        end
    end
end

function relax_integer_vars(m::Model)
    save_integer_values!(m)
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]
        bin = def[:bin]
        int = def[:int]
        indices = def[:indices]
        var = m.ext[:variables][name]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
            fix(var[ind], m.ext[:values][name][ind]; force=true)
            (bin != nothing && bin(ind)) && unset_binary(var[ind])
            (int != nothing && int(ind)) && unset_integer(var[ind])
        end
    end
end

function unrelax_integer_vars(m::Model)
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]
        lb = def[:lb]
        ub = def[:ub]
        bin = def[:bin]
        int = def[:int]
        indices = def[:indices]
        var = m.ext[:variables][name]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
            is_fixed(var[ind]) && unfix(var[ind])
            # `unfix` frees the variable entirely, also bounds
            lb != nothing && set_lower_bound(var[ind], lb(ind))
            ub != nothing && set_upper_bound(var[ind], ub(ind))
            (bin != nothing && bin(ind)) && set_binary(var[ind])
            (int != nothing && int(ind)) && set_integer(var[ind])
        end
    end
end

"""
Save the value of all binary and integer variables so they can be fixed to obtain a dual solution
"""
function save_integer_values!(m::Model)
    for name in m.ext[:integer_variables]
        _save_variable_value!(m, name, m.ext[:variables_definition][name][:indices])
    end
end

function save_marginal_values!(m::Model)
    for (constraint_name, con) in m.ext[:constraints]
        output_name = Symbol(string("constraint_", constraint_name))
        if haskey(m.ext[:outputs], output_name)
            _save_marginal_value!(m, constraint_name, output_name)
        end
    end
end

function _save_marginal_value!(m::Model, constraint_name::Symbol, output_name::Symbol)
    con = m.ext[:constraints][constraint_name]
    inds = keys(con)
    m.ext[:values][output_name] = Dict(
        ind => JuMP.dual(con[ind]) for ind in inds if end_(ind.t) <= end_(current_window(m))
    )
end

function save_bound_marginal_values!(m::Model)
    for (variable_name, con) in m.ext[:variables]
        output_name = Symbol(string("bound_", variable_name))
        if haskey(m.ext[:outputs], output_name)
            _save_bound_marginal_value!(m, variable_name, output_name)
        end
    end
end

function _save_bound_marginal_value!(m::Model, variable_name::Symbol, output_name::Symbol)
    var = m.ext[:variables][variable_name]
    indices = m.ext[:variables_definition][variable_name][:indices]
    m.ext[:values][output_name] = Dict(
        ind => JuMP.reduced_cost(var[ind])
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m))) if end_(ind.t) <= end_(current_window(m))
    )
end
