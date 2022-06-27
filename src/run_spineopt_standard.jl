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
    update_names=false,
    alternative="",
    write_as_roll=0
)
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m)
    init_model!(
        m;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        log_level=log_level,
        alternative_objective=alternative_objective
    )
    init_outputs!(m)
    k = 1
    calculate_duals = any(
        startswith(lowercase(name), r"bound_|constraint_") for name in String.(keys(m.ext[:spineopt].outputs))
    )
    while optimize
        @log log_level 1 "\nWindow $k: $(current_window(m))"
        optimize_model!(m; log_level=log_level, calculate_duals=calculate_duals) || break
        if write_as_roll > 0 && k % write_as_roll == 0
            @timelog log_level 2 "Writing report..." write_report(m, url_out; alternative=alternative)
            clear_results!(m)
        end
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
        k += 1
    end
    @timelog log_level 2 "Writing report..." write_report(m, url_out; alternative=alternative)
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
    @timelog log_level 3 "- [variable_connections_decommissioned]" add_variable_connections_decommissioned!(m)
    @timelog log_level 3 "- [variable_storages_invested]" add_variable_storages_invested!(m)
    @timelog log_level 3 "- [variable_storages_invested_available]" add_variable_storages_invested_available!(m)
    @timelog log_level 3 "- [variable_storages_decommissioned]" add_variable_storages_decommissioned!(m)
    @timelog log_level 3 "- [variable_node_state]" add_variable_node_state!(m)
    @timelog log_level 3 "- [variable_node_slack_pos]" add_variable_node_slack_pos!(m)
    @timelog log_level 3 "- [variable_node_slack_neg]" add_variable_node_slack_neg!(m)
    @timelog log_level 3 "- [variable_node_injection]" add_variable_node_injection!(m)
    @timelog log_level 3 "- [variable_units_invested]" add_variable_units_invested!(m)
    @timelog log_level 3 "- [variable_units_invested_available]" add_variable_units_invested_available!(m)
    @timelog log_level 3 "- [variable_units_mothballed]" add_variable_units_mothballed!(m)
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
    var = m.ext[:spineopt].variables[name]
    bin = m.ext[:spineopt].variables_definition[name][:bin]
    int = m.ext[:spineopt].variables_definition[name][:int]
    for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
        fix_value_ = (fix_value === nothing) ? nothing : fix_value(ind)
        fix_value_ != nothing && !isnan(fix_value_) && fix(var[ind], fix_value_; force=true)
    end
end

"""
Fix all variables in the given model to the values computed by the corresponding `fix_value` parameter function, if any.
"""
function fix_variables!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _fix_variable!(m, name, definition[:indices], definition[:fix_value])
    end
end

function _update_variable!(m::Model, name::Symbol, definition::Dict)
    var = m.ext[:spineopt].variables[name]
    val = m.ext[:spineopt].values[name]
    indices = definition[:indices]
    lb = definition[:lb]
    ub = definition[:ub]
    for ind in indices(m; t=time_slice(m))
        is_fixed(var[ind]) && unfix(var[ind])
        lb != nothing && _set_lower_bound(var[ind], lb(ind))
        ub != nothing && _set_upper_bound(var[ind], ub(ind))
        history_t = t_history_t(m; t=ind.t)
        history_t === nothing && continue
        for history_ind in indices(m; ind..., t=history_t)
            fix(var[history_ind], val[ind]; force=true)
        end
    end
    for ind in indices(m; t=history_time_slice(m))
        is_fixed(var[ind]) && continue
        lb != nothing && _set_lower_bound(var[ind], lb(ind))
        ub != nothing && _set_upper_bound(var[ind], ub(ind))
    end
end

function update_variables!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _update_variable!(m, name, definition)
    end
end

function _fix_non_anticipativity_value!(m, name::Symbol, definition::Dict)
    var = m.ext[:spineopt].variables[name]
    val = m.ext[:spineopt].values[name]
    indices = definition[:indices]
    non_anticipativity_time = definition[:non_anticipativity_time]
    non_anticipativity_margin = definition[:non_anticipativity_margin]

    window_start = start(current_window(m))
    roll_forward_ = roll_forward(model=m.ext[:spineopt].instance)
    for ind in indices(m; t=time_slice(m))
        non_anticipativity_time_ = (non_anticipativity_time === nothing) ? nothing : non_anticipativity_time(ind)
        non_anticipativity_margin_ = (non_anticipativity_margin === nothing) ? nothing : non_anticipativity_margin(ind)
        if non_anticipativity_time_ != nothing && start(ind.t) < window_start +  non_anticipativity_time_
            next_t = to_time_slice(m; t=ind.t + roll_forward_)
            next_inds = indices(m; ind..., t=next_t)
            if !isempty(next_inds)
                next_ind = first(next_inds)
                if non_anticipativity_margin_ != nothing
                    lb = val[next_ind] - non_anticipativity_margin_
                    (lb < 0) && (lb = 0)
                    set_lower_bound(var[ind], lb)

                    ub = val[next_ind] + non_anticipativity_margin_
                    set_upper_bound(var[ind], ub)
                else                    
                    fix(var[ind], val[next_ind]; force=true)
                end
            end
        end
    end
end

function fix_non_anticipativity_values!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
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
    @timelog log_level 3 "- [constraint_connection_lifetime]" add_constraint_connection_lifetime!(m)
    @timelog log_level 3 "- [constraint_connections_invested_transition]" add_constraint_connections_invested_transition!(m)
    @timelog log_level 3 "- [constraint_storages_invested_available]" add_constraint_storages_invested_available!(m)
    @timelog log_level 3 "- [constraint_storage_lifetime]" add_constraint_storage_lifetime!(m)
    @timelog log_level 3 "- [constraint_storages_invested_transition]" add_constraint_storages_invested_transition!(m)
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
    @timelog log_level 3 "- [constraint_unit_lifetime]" add_constraint_unit_lifetime!(m)
    @timelog log_level 3 "- [constraint_units_invested_transition]" add_constraint_units_invested_transition!(m)
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
    for r in model__report(model=m.ext[:spineopt].instance)
        for o in report__output(report=r)
            get!(m.ext[:spineopt].outputs, o.name, Dict{NamedTuple,Dict}())
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
    write_mps_file(model=m.ext[:spineopt].instance) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section.
    @timelog log_level 0 "Optimizing model $(m.ext[:spineopt].instance)..." optimize!(m)
    if termination_status(m) in (MOI.OPTIMAL, MOI.TIME_LIMIT)
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving $(m.ext[:spineopt].instance) results..." save_model_results!(
            m; iterations=iterations
        )
        if calculate_duals
            @log log_level 1 "Setting up final LP of $(m.ext[:spineopt].instance) to obtain duals..."
            @timelog log_level 1 "Copying model" (m_dual_lp, ref_map) = copy_model(m)
            lp_solver = m.ext[:spineopt].lp_solver
            @timelog log_level 1 "Setting LP solver $(lp_solver)..." set_optimizer(m_dual_lp, lp_solver)
            @timelog log_level 1 "Fixing integer variables..." relax_integer_vars(m, ref_map)
            save_marginal_value_promises!(m, ref_map)
            save_bound_marginal_value_promises!(m, ref_map)
            task = Threads.@spawn @timelog log_level 1 "Optimizing LP..." optimize!(m_dual_lp)
            lock(m.ext[:spineopt].dual_solves_lock)
            try
                push!(m.ext[:spineopt].dual_solves, task)
            finally
                unlock(m.ext[:spineopt].dual_solves_lock)
            end
        end
        @timelog log_level 2 "Saving outputs..." save_outputs!(m; iterations=iterations)
        true
    elseif termination_status(m) == MOI.INFEASIBLE
        msg = "model is infeasible - if conflicting constraints can be identified, they will be reported below\n"
        printstyled(msg; bold=true) 
        compute_and_print_conflict!(m)
        false
    else
        @log log_level 0 "Unable to find solution (reason: $(termination_status(m)))"
        write_mps_file(model=m.ext[:spineopt].instance) == :write_mps_on_no_solve && write_to_file(
            m, "model_diagnostics.mps"
        )
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
    var = m.ext[:spineopt].variables[name]
    m.ext[:spineopt].values[name] = Dict(
        ind => _variable_value(var[ind])
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)), temporal_block=anything)
    )
end

"""
Save the value of all variables in a model.
"""
function save_variable_values!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _save_variable_value!(m, name, definition[:indices])
    end
end

_value(v::GenericAffExpr) = JuMP.value(v)
_value(v) = v

"""
Save the value of the objective terms in a model.
"""
function save_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    for name in [objective_terms(m); :total_costs]
        func = eval(name)
        m.ext[:spineopt].values[name] = Dict(ind => _value(realize(func(m, end_(current_window(m))))))
    end
end

function _value_by_entity_non_aggregated(m, value::Dict, crop_to_window)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for (ind, val) in value
        t_keys = collect(_time_slice_keys(ind))
        t = maximum(ind[k] for k in t_keys)
        t <= analysis_time && continue
        crop_to_window && t >= end_(current_window(m)) && continue
        entity = _drop_key(ind, t_keys...)
        entity = _flatten_stochastic_path(entity)
        by_analysis_time_non_aggr = get!(by_entity_non_aggr, entity, Dict{DateTime,Any}())
        by_time_slice_non_aggr = get!(by_analysis_time_non_aggr, analysis_time, Dict{TimeSlice,Any}())
        by_time_slice_non_aggr[t] = val
    end
    by_entity_non_aggr
end

function _flatten_stochastic_path(entity::NamedTuple)
    stoch_path = get(entity, :stochastic_path, nothing)
    stoch_path === nothing && return entity
    flat_stoch_path = (; Dict(Symbol(:stochastic_scenario, k) => scen for (k, scen) in enumerate(stoch_path))...)
    (; _drop_key(entity, :stochastic_path)..., flat_stoch_path...)
end

function _value_by_entity_non_aggregated(m, parameter::Parameter, crop_to_window)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for entity in indices_as_tuples(parameter)
        for (scen, t) in stochastic_time_indices(m)
            crop_to_window && t >= end_(current_window(m)) && continue
            entity = (; entity..., stochastic_scenario=scen)
            val = parameter(; entity..., analysis_time=analysis_time, t=t, _strict=false)
            val === nothing && continue
            by_analysis_time_non_aggr = get!(by_entity_non_aggr, entity, Dict{DateTime,Any}())
            by_time_slice_non_aggr = get!(by_analysis_time_non_aggr, analysis_time, Dict{TimeSlice,Any}())
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

function _save_output!(m, out, value_or_param, crop_to_window; iterations=nothing)
    by_entity_non_aggr = _value_by_entity_non_aggregated(m, value_or_param, crop_to_window)
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
            by_entity = get!(m.ext[:spineopt].outputs, out.name, Dict{NamedTuple,Dict}())
            by_analysis_time = get!(by_entity, entity, Dict{DateTime,Any}())
            by_time_stamp = get(by_analysis_time, analysis_time, nothing)
            if by_time_stamp === nothing
                by_analysis_time[analysis_time] = by_time_stamp_aggr
            else
                merge!(by_time_stamp, by_time_stamp_aggr)
            end
        end
    end
    true
end
_save_output!(m, out, ::Nothing, crop_to_window; iterations=iterations) = false

"""
Save the outputs of a model.
"""
function save_outputs!(m; iterations=nothing)
    reports_by_output = Dict()
    for rpt in model__report(model=m.ext[:spineopt].instance), out in report__output(report=rpt)
        push!(get!(reports_by_output, out, []), rpt)
    end
    is_last_window = end_(current_window(m)) >= model_end(model=m.ext[:spineopt].instance)
    for (out, rpts) in reports_by_output
        value = get(m.ext[:spineopt].values, out.name, nothing)
        crop_to_window = !is_last_window && all(overwrite_results_on_rolling(report=rpt, output=out) for rpt in rpts)
        if _save_output!(m, out, value, crop_to_window; iterations=iterations)
            continue
        end
        param = parameter(out.name, @__MODULE__)
        if _save_output!(m, out, param, crop_to_window; iterations=iterations)
            continue
        end
        @warn "can't find any values for '$(out.name)'"
    end
end

"""
Save a model results: first postprocess results, then save variables and objective values, and finally save outputs
"""
function save_model_results!(m; iterations=nothing)
    postprocess_results!(m)
    save_variable_values!(m)
    save_objective_values!(m)
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
    @timelog log_level 2 "Fixing non-anticipativity values..." fix_non_anticipativity_values!(m)
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Updating constraints..." update_varying_constraints!(m)
    @timelog log_level 2 "Updating user constraints..." update_constraints(m)
    @timelog log_level 2 "Updating objective..." update_varying_objective!(m)
end

function _update_constraint_names!(m)
    for (con_key, cons) in m.ext[:spineopt].constraints
        con_key_raw = string(con_key)
        if occursin(r"[^\x1F-\x7F]+", con_key_raw)
            @warn "constraint $con_key_raw has an illegal character"            
        end
        con_key_clean = _sanitize_constraint_name(con_key_raw)                            
        for (inds, con) in cons        
            constraint_name = _sanitize_constraint_name(string(con_key_clean, inds))                            
            set_name(con, constraint_name)
        end
    end
end

function _sanitize_constraint_name(constraint_name)
    replace(constraint_name, r"[^\x1F-\x7F]+" => "_")
end


function _update_variable_names!(m)
    for (name, var) in m.ext[:spineopt].variables
        for (inds, v) in var
            set_name(v, _base_name(name, inds))
        end
    end
end

function relax_integer_vars(m::Model, ref_map::ReferenceMap)
    # Collect values before calling `fix` on any of the variables to avoid OptimizeNotCalled()
    integers_definition = Dict(
        name => def
        for (name, def) in m.ext[:spineopt].variables_definition
        if def[:bin] !== nothing || def[:int] !== nothing
    )
    values = Dict(
        name => Dict(
            ind => _variable_value(m.ext[:spineopt].variables[name][ind])
            for ind in def[:indices](m; t=vcat(history_time_slice(m), time_slice(m)))
        )
        for (name, def) in integers_definition
    )
    for (name, def) in integers_definition
        bin = def[:bin]
        int = def[:int]
        indices = def[:indices]
        var = m.ext[:spineopt].variables[name]
        vals = values[name]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
            v = var[ind]
            ref_v = ref_map[v]
            val = vals[ind]
            fix(ref_v, val; force=true)
            (bin != nothing && bin(ind)) && unset_binary(ref_v)
            (int != nothing && int(ind)) && unset_integer(ref_v)
        end
    end
end

struct DualPromise
    value::JuMP.ConstraintRef
end

struct ReducedCostPromise
    value::JuMP.VariableRef
end

function save_marginal_value_promises!(m::Model, ref_map::JuMP.ReferenceMap)
    for (constraint_name, con) in m.ext[:spineopt].constraints
        output_name = Symbol(string("constraint_", constraint_name))
        if haskey(m.ext[:spineopt].outputs, output_name)
            _save_marginal_value_promise!(m, con, output_name, ref_map)
        end
    end
end

function _save_marginal_value_promise!(m::Model, con, output_name::Symbol, ref_map::JuMP.ReferenceMap)
    m.ext[:spineopt].values[output_name] = Dict(ind => DualPromise(ref_map[con[ind]]) for ind in keys(con))
end

function save_bound_marginal_value_promises!(m::Model, ref_map::JuMP.ReferenceMap)
    for (variable_name, var) in m.ext[:spineopt].variables
        output_name = Symbol(string("bound_", variable_name))
        if haskey(m.ext[:spineopt].outputs, output_name)
            _save_bound_marginal_value_promise!(m, var, output_name, ref_map)
        end
    end
end

function _save_bound_marginal_value_promise!(m::Model, var, output_name::Symbol, ref_map::JuMP.ReferenceMap)
    m.ext[:spineopt].values[output_name] = Dict(ind => ReducedCostPromise(ref_map[var[ind]]) for ind in keys(var))
end

JuMP.dual(x::DualPromise) = has_duals(owner_model(x.value)) ? dual(x.value) : nothing

JuMP.reduced_cost(x::ReducedCostPromise) = has_duals(owner_model(x.value)) ? reduced_cost(x.value) : nothing

function SpineInterface.db_value(x::TimeSeries{T}) where T <: DualPromise
    db_value(TimeSeries(x.indexes, JuMP.dual.(x.values), x.ignore_year, x.repeat))
end
function SpineInterface.db_value(x::TimeSeries{T}) where T <: ReducedCostPromise
    db_value(TimeSeries(x.indexes, JuMP.reduced_cost.(x.values), x.ignore_year, x.repeat))
end