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

function run_spineopt_standard!(
    m,
    url_out;
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    optimize || return m
    calculate_duals = any(
        startswith(name, r"bound_|constraint_") for name in lowercase.(string.(keys(m.ext[:spineopt].outputs)))
    )
    try
        solve_model!(
            m;
            log_level=log_level,
            update_names=update_names,
            calculate_duals=calculate_duals,
            write_as_roll=write_as_roll,
            resume_file_path=resume_file_path,
        )
        if write_as_roll > 0
            _write_intermediate_results(m)
        else
            write_report(m, url_out; alternative=alternative, log_level=log_level)
        end
        m
    catch err
        showerror(stdout, err, catch_backtrace())
        m
    finally
        if write_as_roll > 0
            write_report_from_intermediate_results(m, url_out; alternative=alternative, log_level=log_level)
        end
    end
end

"""
    build_model!(m; log_level)

Build given SpineOpt model:
- create temporal and stochastic structures
- add variables
- add expressions
- add constraints
- set objective
- initialize outputs


# Arguments
- `log_level::Int`: an integer to control the log level.
"""
function build_model!(m; log_level)
    instance = m.ext[:spineopt].instance
    @timelog log_level 2 "Creating $instance temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating $instance stochastic structure..." generate_stochastic_structure!(m)
    roll_count = m.ext[:spineopt].temporal_structure[:window_count] - 1
    roll_temporal_structure!(m, 1:roll_count)
    @timelog log_level 2 "Adding variables...\n" _add_variables!(m; log_level=log_level)

    @timelog log_level 2 "Adding expressions...\n" _add_expressions!(m; log_level=log_level)
    @timelog log_level 2 "Adding constraints...\n" _add_constraints!(m; log_level=log_level)
    @timelog log_level 2 "Setting objective..." _set_objective!(m)
    _init_outputs!(m)
end

"""
Add SpineOpt variables to the given model.
"""
function _add_variables!(m; log_level=3)
    for add_variable! in (
            add_variable_units_available!,
            add_variable_units_on!,
            add_variable_units_started_up!,
            add_variable_units_shut_down!,
            add_variable_unit_flow!,
            add_variable_unit_flow_op!,
            add_variable_unit_flow_op_active!,
            add_variable_connection_flow!,
            add_variable_connection_intact_flow!,
            add_variable_connections_invested!,
            add_variable_connections_invested_available!,
            add_variable_connections_decommissioned!,
            add_variable_storages_invested!,
            add_variable_storages_invested_available!,
            add_variable_storages_decommissioned!,
            add_variable_node_state!,
            add_variable_node_slack_pos!,
            add_variable_node_slack_neg!,
            add_variable_node_injection!,
            add_variable_units_invested!,
            add_variable_units_invested_available!,
            add_variable_units_mothballed!,
            add_variable_nonspin_units_started_up!,
            add_variable_nonspin_units_shut_down!,
            add_variable_units_out_of_service!,
            add_variable_units_taken_out_of_service!,
            add_variable_units_returned_to_service!,
            add_variable_node_pressure!,
            add_variable_node_voltage_angle!,
            add_variable_binary_gas_connection_flow!,
            add_variable_user_constraint_slack_pos!,
            add_variable_user_constraint_slack_neg!,
            add_variable_min_capacity_margin_slack!,
        )
        name = name_from_fn(add_variable!)
        @timelog log_level 3 "- [$name]" add_variable!(m)
    end
end

"""
Add SpineOpt expressions to the given model.
"""
function _add_expressions!(m; log_level=3)
    for add_expression! in (
            add_expression_capacity_margin!,
        )
        name = name_from_fn(add_expression!)
        @timelog log_level 3 "- [$name]" add_expression!(m)
    end        
end


"""
Add SpineOpt constraints to the given model.
"""
function _add_constraints!(m; log_level=3)
    for add_constraint! in (
            add_constraint_min_capacity_margin!,
            add_constraint_unit_pw_heat_rate!,
            add_constraint_user_constraint!,
            add_constraint_node_injection!,
            add_constraint_nodal_balance!,
            add_constraint_candidate_connection_flow_ub!,
            add_constraint_candidate_connection_flow_lb!,
            add_constraint_connection_intact_flow_ptdf!,
            add_constraint_connection_flow_intact_flow!,
            add_constraint_connection_flow_lodf!,
            add_constraint_connection_flow_capacity!,
            add_constraint_connection_flow_capacity_bidirection!,
            add_constraint_connection_intact_flow_capacity!,
            add_constraint_unit_flow_capacity!,
            add_constraint_connections_invested_available!,
            add_constraint_connection_lifetime!,
            add_constraint_connections_invested_transition!,
            add_constraint_storages_invested_available!,
            add_constraint_storage_lifetime!,
            add_constraint_storages_invested_transition!,
            add_constraint_operating_point_bounds!,
            add_constraint_operating_point_rank!,
            add_constraint_unit_flow_op_bounds!,
            add_constraint_unit_flow_op_rank!,
            add_constraint_unit_flow_op_sum!,
            add_constraint_fix_ratio_out_in_unit_flow!,
            add_constraint_max_ratio_out_in_unit_flow!,
            add_constraint_min_ratio_out_in_unit_flow!,
            add_constraint_fix_ratio_out_out_unit_flow!,
            add_constraint_max_ratio_out_out_unit_flow!,
            add_constraint_min_ratio_out_out_unit_flow!,
            add_constraint_fix_ratio_in_in_unit_flow!,
            add_constraint_max_ratio_in_in_unit_flow!,
            add_constraint_min_ratio_in_in_unit_flow!,
            add_constraint_fix_ratio_in_out_unit_flow!,
            add_constraint_max_ratio_in_out_unit_flow!,
            add_constraint_min_ratio_in_out_unit_flow!,
            add_constraint_ratio_out_in_connection_intact_flow!,
            add_constraint_fix_ratio_out_in_connection_flow!,
            add_constraint_max_ratio_out_in_connection_flow!,
            add_constraint_min_ratio_out_in_connection_flow!,
            add_constraint_node_state_capacity!,
            add_constraint_cyclic_node_state!,
            add_constraint_max_total_cumulated_unit_flow_from_node!,
            add_constraint_min_total_cumulated_unit_flow_from_node!,
            add_constraint_max_total_cumulated_unit_flow_to_node!,
            add_constraint_min_total_cumulated_unit_flow_to_node!,
            add_constraint_units_on!,
            add_constraint_units_available!,
            add_constraint_units_invested_available!,
            add_constraint_unit_lifetime!,
            add_constraint_units_invested_transition!,
            add_constraint_minimum_operating_point!,
            add_constraint_min_down_time!,
            add_constraint_min_up_time!,
            add_constraint_unit_state_transition!,
            add_constraint_min_scheduled_outage_duration!,
            add_constraint_units_out_of_service_contiguity!,
            add_constraint_units_out_of_service_transition!,
            add_constraint_ramp_up!,
            add_constraint_ramp_down!,
            add_constraint_non_spinning_reserves_lower_bound!,
            add_constraint_non_spinning_reserves_start_up_upper_bound!,
            add_constraint_non_spinning_reserves_shut_down_upper_bound!,
            add_constraint_res_minimum_node_state!,
            add_constraint_fix_node_pressure_point!,
            add_constraint_connection_unitary_gas_flow!,
            add_constraint_compression_ratio!,
            add_constraint_storage_line_pack!,
            add_constraint_connection_flow_gas_capacity!,
            add_constraint_max_node_pressure!,
            add_constraint_min_node_pressure!,
            add_constraint_node_voltage_angle!,
            add_constraint_max_node_voltage_angle!,
            add_constraint_min_node_voltage_angle!,
            add_constraint_investment_group_equal_investments!,
            add_constraint_investment_group_minimum_entities_invested_available!,
            add_constraint_investment_group_maximum_entities_invested_available!,
            add_constraint_investment_group_minimum_capacity_invested_available!,
            add_constraint_investment_group_maximum_capacity_invested_available!,            
        )
        name = name_from_fn(add_constraint!)
        @timelog log_level 3 "- [$name]" add_constraint!(m)
    end
    _update_constraint_names!(m)
end

function _set_objective!(m::Model)
    _create_objective_terms!(m)
    total_discounted_costs = sum(
        in_window + beyond_window for (in_window, beyond_window) in values(m.ext[:spineopt].objective_terms)
    )
    if !iszero(total_discounted_costs)
        @objective(m, Min, total_discounted_costs)
    else
        @warn "no objective terms defined"
    end
end

function _create_objective_terms!(m)
    window_end = end_(current_window(m))
    window_very_end = maximum(end_.(time_slice(m)))
    beyond_window = collect(to_time_slice(m; t=TimeSlice(window_end, window_very_end)))
    in_window = collect(to_time_slice(m; t=current_window(m)))
    filter!(t -> !(t in beyond_window), in_window)
    for term in objective_terms(
        m; operations=true, investments=model_type(model=m.ext[:spineopt].instance) !== :spineopt_benders
    )
        func = eval(term)
        m.ext[:spineopt].objective_terms[term] = (func(m, in_window), func(m, beyond_window))
    end
end

function _init_outputs!(m::Model)
    for out in keys(m.ext[:spineopt].reports_by_output)
        get!(m.ext[:spineopt].outputs, out.name, Dict{NamedTuple,Dict}())
    end
end

"""
    solve_model!(m; <keyword arguments>)

Solve given SpineOpt model and save outputs.

# Arguments
- `log_level::Int=3`: an integer to control the log level.
- `update_names::Bool=false`: whether or not to update variable and constraint names after the model rolls
   (expensive).
- `write_as_roll::Int=0`: if greater than 0 and the run has a rolling horizon, then write results every that many
   windows.
- `resume_file_path::String=nothing`: only relevant in rolling horizon optimisations with `write_as_roll` greater or
   equal than one. If the file at given path contains resume data from a previous run, start the run from that point.
   Also, save resume data to that same file as the model rolls and results are written to the output database.
- `calculate_duals::Bool=false`: whether or not to calculate duals after the model solve.
- `output_suffix::NamedTuple=(;)`: to add to the outputs.
- `log_prefix::String`="": to prepend to log messages.
- `slice_to_stamp=t -> (start(t),)`: a function that takes a `TimeSlice` and returns a sequence of `DateTime`s.
"""
function solve_model!(
    m;
    log_level=3,
    update_names=false,
    write_as_roll=0,
    resume_file_path=nothing,
    calculate_duals=false,
    output_suffix=(;),
    log_prefix="",
    slice_to_stamp=t -> (start(t),),
)
    k = _resume_run!(m, resume_file_path; log_level, update_names)
    k === nothing && return m
    _call_event_handlers(m, :model_about_to_solve; log_prefix)
    @timelog log_level 2 "Bringing $(m.ext[:spineopt].instance) to the first window..." rewind_temporal_structure!(m)
    while true
        @log log_level 1 "\n$(log_prefix)Window $k: $(current_window(m))"
        _call_event_handlers(m, :window_about_to_solve, k; log_prefix)
        optimize_model!(m; log_level, calculate_duals, output_suffix, slice_to_stamp) || return false
        _save_window_state(m, k; write_as_roll, resume_file_path)
        _call_event_handlers(m, :window_solved, k; log_prefix)
        if @timelog log_level 2 "$(log_prefix)Rolling temporal structure...\n" !roll_temporal_structure!(m, k)
            @timelog log_level 2 "$(log_prefix) ... Rolling complete\n" break
        end
        update_model!(m; log_level=log_level, update_names=update_names)
        k += 1
    end
    _call_event_handlers(m, :model_solved)
    true
end

_resume_run!(m, ::Nothing; log_level, update_names) = 1
function _resume_run!(m, resume_file_path; log_level, update_names)
    !isfile(resume_file_path) && return 1
    try
        resume_data = JSON.parsefile(resume_file_path)
        k, values = resume_data["window"], resume_data["values"]
        @log log_level 1 "Using data from $resume_file_path to skip through windows 1 to $k..."
        roll_temporal_structure!(m, 1:(k - 1))
        _load_variable_values!(m, values)
        if !roll_temporal_structure!(m, k)
            @log log_level 1 "Nothing to resume - window $k was the last one"
            nothing
        else
            update_model!(m; log_level=log_level, update_names=update_names)
            k + 1
        end
    catch err
        @log log_level 1 "Couldn't resume run from $resume_file_path - $err"
        1
    end
end

function _load_variable_values!(m::Model, values)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _load_variable_value!(m, name, definition[:indices], values)
    end
    m.ext[:spineopt].has_results[] = true
end

function _load_variable_value!(m::Model, name::Symbol, indices::Function, values)
    m.ext[:spineopt].values[name] = Dict(
        ind => values[string(name)][string(ind)]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)), temporal_block=anything)
    )
end

"""
Optimize the given model.
If an optimal solution is found, save results and return `true`, otherwise return `false`.
"""
function optimize_model!(
    m::Model; log_level=3, calculate_duals=false, output_suffix=(;), slice_to_stamp=t -> (start(t),)
)
    write_mps_file(model=m.ext[:spineopt].instance) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section.
    @timelog log_level 0 "Optimizing model $(m.ext[:spineopt].instance)..." optimize!(m)
    termination_st = termination_status(m)
    if termination_st in (MOI.OPTIMAL, MOI.TIME_LIMIT)
        if result_count(m) > 0
            solution_type = termination_st == MOI.OPTIMAL ? "Optimal" : "Feasible"
            @log log_level 1 "$solution_type solution found, objective function value: $(objective_value(m))"
            m.ext[:spineopt].has_results[] = true
            @timelog log_level 2 "Saving $(m.ext[:spineopt].instance) results..." _save_model_results!(m)
            calculate_duals && _calculate_duals(m; log_level=log_level)
            @timelog log_level 2 "Postprocessing results..." postprocess_results!(m)
            @timelog log_level 2 "Saving outputs..." _save_outputs!(m; output_suffix, slice_to_stamp)
        else
            m.ext[:spineopt].has_results[] = false
            @warn "no solution available for window $(current_window(m)) - moving on..."
        end
        true
    elseif termination_st == MOI.INFEASIBLE
        printstyled(
            "model is infeasible - if conflicting constraints can be identified, they will be reported below\n";
            bold=true
        )
        try
            _compute_and_print_conflict!(m)
        catch err
            @info err.msg
        end
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
Save a model results: first postprocess results, then save variables and objective values, and finally save outputs
"""
function _save_model_results!(m)
    _save_variable_values!(m)
    _save_constraint_values!(m)
    _save_objective_values!(m)
    _save_other_values!(m)
end

"""
Save the value of all variables in a model.
"""
function _save_variable_values!(m::Model)
    for (name, var) in m.ext[:spineopt].variables
        m.ext[:spineopt].values[name] = Dict(ind => _variable_value(v) for (ind, v) in var)
    end
end

function _save_other_values!(m::Model)
    try
        m.ext[:spineopt].values[:relative_optimality_gap] = Dict(
            (model=m.ext[:spineopt].instance, t=current_window(m),) => JuMP.MOI.get(m, JuMP.MOI.RelativeGap())
        )
    catch err
        @warn err
    end
end

"""
Save the value of all constraints if the user wants to report it.
"""
function _save_constraint_values!(m::Model)
    for (name, con) in m.ext[:spineopt].constraints
        name = Symbol(:value_constraint_, name)
        name in keys(m.ext[:spineopt].outputs) || continue
        m.ext[:spineopt].values[name] = Dict(ind => JuMP.value(c) for (ind, c) in con)
    end
end

"""
The value of a JuMP variable, rounded if necessary.
"""
_variable_value(v::VariableRef) = (is_integer(v) || is_binary(v)) ? round(Int, JuMP.value(v)) : JuMP.value(v)
_variable_value(x::Call) = realize(x)

"""
Save the value of the objective terms in a model.
"""
function _save_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    total_costs = total_costs_tail = 0
    for (term, (in_window, beyond_window)) in m.ext[:spineopt].objective_terms
        cost, cost_tail = JuMP.value(realize(in_window)), JuMP.value(realize(beyond_window))
        total_costs += cost
        total_costs_tail += cost_tail
        m.ext[:spineopt].values[term] = Dict(ind => cost)
    end
    m.ext[:spineopt].values[:total_costs] = Dict(ind => total_costs)
    m.ext[:spineopt].values[:total_costs_tail] = Dict(ind => total_costs_tail)
    nothing
end

function _save_window_state(m, k; write_as_roll, resume_file_path)
    if write_as_roll > 0 && k % write_as_roll == 0
        _write_intermediate_results(m)
        _dump_resume_data(m, k, resume_file_path)
        _clear_results!(m)
    end
end

function _calculate_duals(m; log_level=3)
    if has_duals(m)
        _save_marginal_values!(m)
        _save_bound_marginal_values!(m)
    elseif model_type(model=m.ext[:spineopt].instance) !== :spineopt_benders
        @log log_level 1 "Obtaining duals for $(m.ext[:spineopt].instance)..."
        _calculate_duals_cplex(m; log_level=log_level) && return
        _calculate_duals_fallback(m; log_level=log_level)
    else
        @log log_level 1 "Obtaining duals for $(m.ext[:spineopt].instance) to generate Benders cuts..."
        _calculate_duals_fallback(m; log_level=log_level, for_benders=true)
    end
end

function _calculate_duals_cplex(m; log_level=3)
    CPLEX = Base.invokelatest(get_module, :CPLEX)
    CPLEX === nothing && return false
    model_backend = backend(m)
    cplex_model = JuMP.mode(m) == JuMP.DIRECT ? model_backend : model_backend.optimizer.model
    cplex_model isa CPLEX.Optimizer || return false
    prob_type = CPLEX.CPXgetprobtype(cplex_model.env, cplex_model.lp)
    @assert prob_type == CPLEX.CPXPROB_MILP
    CPLEX.CPXchgprobtype(cplex_model.env, cplex_model.lp, CPLEX.CPXPROB_FIXEDMILP)
    @timelog log_level 1 "Optimizing LP..." ret = CPLEX.CPXlpopt(cplex_model.env, cplex_model.lp)
    if ret == 0
        try
            _save_marginal_values!(m)
            _save_bound_marginal_values!(m, v -> _reduced_cost_cplex(v, cplex_model, CPLEX))
        catch err
            @error err
            CPLEX.CPXchgprobtype(cplex_model.env, cplex_model.lp, prob_type)
            return false
        end
    end
    CPLEX.CPXchgprobtype(cplex_model.env, cplex_model.lp, prob_type)
    ret == 0
end

function _reduced_cost_cplex(v::VariableRef, cplex_model, CPLEX)
    m = owner_model(v)
    sign = objective_sense(m) == MIN_SENSE ? 1.0 : -1.0
    col = Cint(CPLEX.column(cplex_model, index(v)) - 1)
    p = Ref{Cdouble}()
    CPLEX.CPXgetdj(cplex_model.env, cplex_model.lp, p, col, col)
    rc = p[]
    sign * rc
end

function _calculate_duals_fallback(m; log_level=3, for_benders=false)
    @timelog log_level 1 "Copying model" (m_dual_lp, ref_map) = copy_model(m)
    lp_solver = m.ext[:spineopt].lp_solver
    @timelog log_level 1 "Setting LP solver $(lp_solver)..." set_optimizer(m_dual_lp, lp_solver)
    if for_benders
        @timelog log_level 1 "Relaxing discrete variables..." _relax_discrete_vars!(m, ref_map)
    else
        @timelog log_level 1 "Fixing discrete variables..." _relax_discrete_vars!(m, ref_map; and_fix=true)
    end
    dual_fallback(con) = DualPromise(ref_map[con])
    reduced_cost_fallback(var) = ReducedCostPromise(ref_map[var])
    _save_marginal_values!(m, dual_fallback)
    _save_bound_marginal_values!(m, reduced_cost_fallback)
    if isdefined(Threads, Symbol("@spawn"))
        task = Threads.@spawn @timelog log_level 1 "Optimizing LP..." optimize!(m_dual_lp)
        lock(m.ext[:spineopt].dual_solves_lock)
        try
            push!(m.ext[:spineopt].dual_solves, task)
        finally
            unlock(m.ext[:spineopt].dual_solves_lock)
        end
    else
        @timelog log_level 1 "Optimizing LP..." optimize!(m_dual_lp)
    end
end

function _relax_discrete_vars!(m::Model, ref_map::ReferenceMap; and_fix=false)
    for (name, var) in m.ext[:spineopt].variables
        def = m.ext[:spineopt].variables_definition[name]
        def[:bin] === def[:int] === nothing && continue
        for v in values(var)
            v isa VariableRef || continue
            ref_v = ref_map[v]
            if is_binary(ref_v)
                unset_binary(ref_v)
            elseif is_integer(ref_v)
                unset_integer(ref_v)
            else
                continue
            end
            if and_fix
                val = _variable_value(v)
                fix(ref_v, val; force=true)
            end
        end
    end
end

function _save_marginal_values!(m::Model, dual=JuMP.dual)
    for (constraint_name, con) in m.ext[:spineopt].constraints
        name = Symbol(string("constraint_", constraint_name))
        m.ext[:spineopt].values[name] = Dict(i => dual(c) for (i, c) in con if c isa ConstraintRef)
    end
end

function _save_bound_marginal_values!(m::Model, reduced_cost=JuMP.reduced_cost)
    for (variable_name, var) in m.ext[:spineopt].variables
        name = Symbol(string("bound_", variable_name))
        m.ext[:spineopt].values[name] = Dict(i => reduced_cost(v) for (i, v) in var if v isa VariableRef)
    end
end

"""
Save the outputs of a model.
"""
function _save_outputs!(m; output_suffix, slice_to_stamp)
    is_last_window = end_(current_window(m)) >= model_end(model=m.ext[:spineopt].instance)
    for (out, rpts) in m.ext[:spineopt].reports_by_output
        value = get(m.ext[:spineopt].values, out.name, nothing)
        crop_to_window = !is_last_window && all(overwrite_results_on_rolling(report=rpt, output=out) for rpt in rpts)
        if _save_output!(m, out, value, crop_to_window; output_suffix, slice_to_stamp)
            continue
        end
        param = parameter(out.name, @__MODULE__)
        if _save_output!(m, out, param, crop_to_window; output_suffix, slice_to_stamp)
            continue
        end
        @warn "can't find any values for '$(out.name)'"
    end
end

function _save_output!(m, out, value_or_param, crop_to_window; output_suffix, slice_to_stamp)
    by_entity_non_aggr = _value_by_entity_non_aggregated(m, value_or_param, crop_to_window)
    for (entity, by_analysis_time_non_aggr) in by_entity_non_aggr
        entity = (; entity..., output_suffix...)
        for (analysis_time, by_time_slice_non_aggr) in by_analysis_time_non_aggr
            t_highest_resolution!(by_time_slice_non_aggr)
            output_time_slices_ = output_time_slices(m; output=out)
            by_time_stamp_aggr = _value_by_time_stamp_aggregated(
                by_time_slice_non_aggr, output_time_slices_, slice_to_stamp
            )
            isempty(by_time_stamp_aggr) && continue
            by_entity = get!(m.ext[:spineopt].outputs, out.name, Dict{NamedTuple,Dict}())
            by_analysis_time = get!(by_entity, entity, Dict{DateTime,Any}())
            current_by_time_slice_aggr = get(by_analysis_time, analysis_time, nothing)
            if current_by_time_slice_aggr === nothing
                by_analysis_time[analysis_time] = by_time_stamp_aggr
            else
                merge!(current_by_time_slice_aggr, by_time_stamp_aggr)
            end
        end
    end
    true
end
_save_output!(m, out, ::Nothing, crop_to_window; output_suffix, slice_to_stamp) = false

function _value_by_entity_non_aggregated(m, value::Dict, crop_to_window)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for (ind, val) in value
        t_keys = collect(_time_slice_keys(ind))
        t = !isempty(t_keys) ? maximum(ind[k] for k in t_keys) : current_window(m)
        t <= analysis_time && continue
        crop_to_window && start(t) >= end_(current_window(m)) && continue
        entity = _drop_key(ind, t_keys...)
        by_analysis_time_non_aggr = get!(by_entity_non_aggr, entity, Dict{DateTime,Any}())
        by_time_slice_non_aggr = get!(by_analysis_time_non_aggr, analysis_time, Dict{TimeSlice,Any}())
        by_time_slice_non_aggr[t] = val
    end
    by_entity_non_aggr
end
function _value_by_entity_non_aggregated(m, parameter::Parameter, crop_to_window)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for entity in indices_as_tuples(parameter)
        for (scen, t) in stochastic_time_indices(m)
            crop_to_window && start(t) >= end_(current_window(m)) && continue
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

function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, output_time_slices::Array, slice_to_stamp)
    by_time_stamp_aggr = Dict()
    for t_aggr in output_time_slices
        time_slices = filter(t -> iscontained(t, t_aggr), keys(by_time_slice_non_aggr))
        isempty(time_slices) && continue  # No aggregation possible
        val = sum(by_time_slice_non_aggr[t] for t in time_slices) / length(time_slices)
        for i in slice_to_stamp(t_aggr)
            by_time_stamp_aggr[i] = val
        end
    end
    by_time_stamp_aggr
end
function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, ::Nothing, slice_to_stamp)
    Dict(i => v for (t, v) in by_time_slice_non_aggr for i in slice_to_stamp(t))
end

function _compute_and_print_conflict!(m)
    compute_conflict!(m)    
    for (f, s) in list_of_constraint_types(m)
        for con in all_constraints(m, f, s)
            if MOI.get(m, MOI.ConstraintConflictStatus(), con) == MOI.IN_CONFLICT                
                println(con)
            end
        end
    end
end

_entity_name(entity::ObjectLike) = entity.name
_entity_name(entities::Vector{T}) where {T<:ObjectLike} = [entity.name for entity in entities]

function _write_intermediate_results(m)
    values = _collect_output_values(m)
    tables = []
    for ((output_name, overwrite), by_entity) in values
        table = [
            ((; (class => _entity_name(ent) for (class, ent) in pairs(entity))...), index, value)
            for (entity, val) in by_entity
            for (index, value) in indexed_values(val)
        ]
        isempty(table) && continue
        file_path = joinpath(m.ext[:spineopt].intermediate_results_folder, _output_file_name(output_name, overwrite))
        push!(tables, (file_path, table))
    end
    isempty(tables) && return
    file_path = joinpath(m.ext[:spineopt].intermediate_results_folder, ".report_name_keys_by_url")
    if !isfile(file_path)
        @info """
        Intermediate results are being written to $(m.ext[:spineopt].intermediate_results_folder).

        These results will be cleared automatically when written to the DB.
        However if your run fails before this can happen, you can write them manually by running

            write_report_from_intermediate_results(raw"$(m.ext[:spineopt].intermediate_results_folder)", url_out)

        """
        open(file_path, "w") do f
            JSON.print(f, m.ext[:spineopt].report_name_keys_by_url)
        end
    end
    for (file_path, table) in tables
        isfile(file_path) ? Arrow.append(file_path, table) : Arrow.write(file_path, table; file=false)
    end
end

function _output_keys(report_name_keys_by_url)
    unique(
        key
        for report_name_keys in values(report_name_keys_by_url)
        for (_rpt_name, keys) in report_name_keys
        for key in keys
    )
end

"""
    write_report_from_intermediate_results(intermediate_results_folder, default_url; <keyword arguments>)

Collect results generated on a previous, unsuccessful SpineOpt run from `intermediate_results_folder`, and
write the corresponding report(s) to `url_out`.
A new Spine database is created at `url_out` if one doesn't exist.

# Arguments

- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.

- `log_level::Int=3`: an integer to control the log level.
"""
function write_report_from_intermediate_results(
    x::Union{Model,AbstractString}, default_url; alternative="", log_level=3
)
    intermediate_results_folder = _intermediate_results_folder(x)
    report_name_keys_by_url = _report_name_keys_by_url(x)
    values = _collect_values_from_intermediate_results(intermediate_results_folder, report_name_keys_by_url)
    isempty(values) || write_report(
        report_name_keys_by_url, default_url, values; alternative=alternative, log_level=log_level
    )
    _clear_intermediate_results(x)
end

_intermediate_results_folder(m::Model) = m.ext[:spineopt].intermediate_results_folder
_intermediate_results_folder(intermediate_results_folder::AbstractString) = intermediate_results_folder

_report_name_keys_by_url(m::Model) = m.ext[:spineopt].report_name_keys_by_url
function _report_name_keys_by_url(intermediate_results_folder::AbstractString)
    JSON.parsefile(joinpath(intermediate_results_folder, ".report_name_keys_by_url"))
end

function _collect_values_from_intermediate_results(intermediate_results_folder, report_name_keys_by_url)
    values = Dict()
    for (output_name, overwrite) in _output_keys(report_name_keys_by_url)
        file_path = joinpath(intermediate_results_folder, _output_file_name(output_name, overwrite))
        isfile(file_path) || continue
        table = Arrow.Table(file_path)
        by_entity = Dict()
        for (entity, index, value) in zip(table...)
            push!(get!(by_entity, entity, Dict{typeof(index),Any}()), index => value)
        end
        values[output_name, overwrite] = Dict(entity => collect_indexed_values(vals) for (entity, vals) in by_entity)
    end
    values
end

_output_file_name(output_name, overwrite) = string(output_name, overwrite ? "1" : "0")

_clear_intermediate_results(m::Model) = _clear_intermediate_results(m.ext[:spineopt].intermediate_results_folder)
function _clear_intermediate_results(intermediate_results_folder::AbstractString)
    function _do_clear_intermediate_results(; p=intermediate_results_folder)
        _prepare_for_deletion(p)
        rm(p; force=true, recursive=true)
        @info "cleared intermediate results from $p - either empty or already in the DB"
    end

    try
        _do_clear_intermediate_results()
    catch
        atexit(_do_clear_intermediate_results)
    end
end

function _prepare_for_deletion(path::AbstractString)
    # Nothing to do for non-directories
    if !isdir(path)
        return
    end

    try chmod(path, filemode(path) | 0o333)
    catch; end
    for (root, dirs, files) in walkdir(path; onerror=x->())
        for dir in dirs
            dpath = joinpath(root, dir)
            try chmod(dpath, filemode(dpath) | 0o333)
            catch; end
        end
    end
end

"""
    write_report(m, default_url, output_value=output_value; alternative="")

Write report from given model into a DB.

# Arguments
- `m::Model`: a SpineOpt model.
- `default_url::String`: a DB url to write the report to.
- `output_value`: a function to replace `SpineOpt.output_value`.

# Keyword arguments
- `alternative::String`: an alternative to pass to `SpineInterface.write_parameters`.
"""
function write_report(m, default_url, output_value=output_value; alternative="", log_level=3)
    default_url === nothing && return
    values = _collect_output_values(m, output_value)
    write_report(m, default_url, values; alternative=alternative, log_level=log_level)
end
function write_report(m, default_url, values::Dict; alternative="", log_level=3)
    write_report(
        m.ext[:spineopt].report_name_keys_by_url, default_url, values, alternative=alternative, log_level=log_level
    )
end
function write_report(report_name_keys_by_url::Dict, default_url, values::Dict; alternative="", log_level=3)
    for (output_url, report_name_keys) in report_name_keys_by_url
        url = output_url !== nothing ? output_url : default_url
        actual_url = run_request(url, "get_db_url")
        @timelog log_level 2 "Writing report to $actual_url..." for (report_name, keys) in report_name_keys
            vals = Dict()
            for (output_name, overwrite) in keys
                value = get(values, (output_name, overwrite), nothing)
                value === nothing && continue
                output_name = output_name in all_objective_terms ? Symbol("objective_", output_name) : output_name
                vals[output_name] = Dict(_flatten_stochastic_path(ent) => val for (ent, val) in value)
            end
            write_parameters(vals, url; report=string(report_name), alternative=alternative, on_conflict="merge")
        end
    end
end

function _collect_output_values(m, output_value=output_value)
    _wait_for_dual_solves(m)
    values = Dict()
    for (output_name, overwrite) in _output_keys(m.ext[:spineopt].report_name_keys_by_url)
        by_entity = get(m.ext[:spineopt].outputs, output_name, nothing)
        by_entity === nothing && continue
        key = (output_name, overwrite)
        haskey(values, key) && continue
        values[key] = _output_value_by_entity(by_entity, overwrite, output_value)
    end
    values
end

function _wait_for_dual_solves(m)
    lock(m.ext[:spineopt].dual_solves_lock)
    try
        wait.(m.ext[:spineopt].dual_solves)
        empty!(m.ext[:spineopt].dual_solves)
    finally
        unlock(m.ext[:spineopt].dual_solves_lock)
    end
end

function _output_value_by_entity(by_entity, overwrite_results_on_rolling, output_value=output_value)
    Dict(
        entity => output_value(by_analysis_time, overwrite_results_on_rolling)
        for (entity, by_analysis_time) in by_entity
    )
end

"""
    output_value(by_analysis_time, overwrite_results_on_rolling)

A `TimeSeries` or `Map` from a result of SpineOpt.

# Arguments
- `by_analysis_time::Dict`: mapping `DateTime` analysis time, to `TimeSlice`, to value.
- `overwrite_results_on_rolling::Bool`: if `true`, ignore the analysis times and return a `TimeSeries`.
    If `false`, return a `Map` where the topmost keys are the analysis times.
"""
function output_value(by_analysis_time, overwrite_results_on_rolling::Bool)
    by_analysis_time_realized = Dict(
        analysis_time => Dict(time_stamp => realize(value) for (time_stamp, value) in by_time_stamp)
        for (analysis_time, by_time_stamp) in by_analysis_time
    )
    _output_value(by_analysis_time_realized, Val(overwrite_results_on_rolling))
end

function _output_value(by_analysis_time, overwrite_results_on_rolling::Val{true})
    by_analysis_time_sorted = sort(OrderedDict(by_analysis_time))
    by_time_stamp = ((t, val) for by_time_stamp in values(by_analysis_time_sorted) for (t, val) in by_time_stamp)
    TimeSeries(_indices_and_values(by_time_stamp)...; merge_ok=true)
end
function _output_value(by_analysis_time, overwrite_results_on_rolling::Val{false})
    Map(
        collect(keys(by_analysis_time)),
        [TimeSeries(_indices_and_values(by_time_stamp)...) for by_time_stamp in values(by_analysis_time)]
    )
end

function _indices_and_values(by_time_stamp)
    indices, values = zip(by_time_stamp...)
    collect(indices), collect(values)
end

function _flatten_stochastic_path(entity::NamedTuple)
    stoch_path = get(entity, :stochastic_path, nothing)
    stoch_path === nothing && return entity
    flat_stoch_path = (; Dict(Symbol(:stochastic_scenario, k) => scen for (k, scen) in enumerate(stoch_path))...)
    (; _drop_key(entity, :stochastic_path)..., flat_stoch_path...)
end

function _dump_resume_data(m::Model, k, ::Nothing) end
function _dump_resume_data(m::Model, k, resume_file_path)
    resume_data = Dict("values" => m.ext[:spineopt].values, "window" => k)
    open(resume_file_path, "w") do f
        JSON.print(f, resume_data, 4)
    end
end

function _clear_results!(m)
    for out in output()
        by_entity = get!(m.ext[:spineopt].outputs, out.name, nothing)
        by_entity === nothing && continue
        empty!(by_entity)
    end
end

"""
Update the given model for the next window in the rolling horizon: update variables, fix the necessary variables,
update constraints and update objective.
"""
function update_model!(m; log_level=3, update_names=false)
    if update_names
        _update_variable_names!(m)
        _update_constraint_names!(m)
    end
    m.ext[:spineopt].has_results[] || return
    @timelog log_level 2 "Fixing history..." _fix_history!(m)
    @timelog log_level 2 "Applying non-anticipativity constraints..." apply_non_anticipativity_constraints!(m)
end

function _update_variable_names!(m, names=keys(m.ext[:spineopt].variables))
    for name in names   
        var = m.ext[:spineopt].variables[name]
        # NOTE: only update names for the representative variables
        # This is achieved by using the indices function from the variable definition
        for ind in m.ext[:spineopt].variables_definition[name][:indices](m; t=[time_slice(m); history_time_slice(m)])
            _set_name(var[ind], _base_name(name, ind))
        end
    end
end

function _update_constraint_names!(m, names=keys(m.ext[:spineopt].constraints))
    for name in names   
        for (ind, con) in m.ext[:spineopt].constraints[name]        
            constraint_name = _sanitize_constraint_name(string(name, ind))                            
            _set_name(con, constraint_name)
        end
    end
end

function _sanitize_constraint_name(constraint_name)
    pattern = r"[^\x1F-\x7F]+"
    occursin(pattern, constraint_name) && @warn "constraint $constraint_name has an illegal character"
    replace(constraint_name, pattern => "_")
end

_set_name(x::Union{VariableRef,ConstraintRef}, name) = set_name(x, name)
_set_name(::Union{Call,Nothing}, name) = nothing

function _fix_history!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _fix_history_variable!(m, name, definition[:indices])
    end
end

function _fix_history_variable!(m::Model, name::Symbol, indices)
    var = m.ext[:spineopt].variables[name]
    val = m.ext[:spineopt].values[name]
    for ind in indices(m; t=time_slice(m))
        history_t = t_history_t(m; t=ind.t)
        history_t === nothing && continue
        for history_ind in indices(m; ind..., t=history_t)
            _fix(var[history_ind], val[ind])
        end
    end
end

_fix(v::VariableRef, x) = fix(v, x; force=true)
_fix(::Call, x) = nothing

function apply_non_anticipativity_constraints!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _apply_non_anticipativity_constraint!(m, name, definition)
    end
end

function _apply_non_anticipativity_constraint!(m, name::Symbol, definition::Dict)
    var = m.ext[:spineopt].variables[name]
    val = m.ext[:spineopt].values[name]
    indices = definition[:indices]
    non_anticipativity_time = definition[:non_anticipativity_time]
    non_anticipativity_time === nothing && return
    non_anticipativity_margin = definition[:non_anticipativity_margin]
    w_start = start(current_window(m))
    w_length = end_(current_window(m)) - w_start
    for ent in indices_as_tuples(non_anticipativity_time)
        for ind in indices(m; t=time_slice(m), ent...)
            non_ant_time = non_anticipativity_time(; ind..., _strict=false)
            non_ant_margin = if non_anticipativity_margin === nothing
                nothing
            else
                non_anticipativity_margin(; ind..., _strict=false)
            end
            if non_ant_time != nothing && start(ind.t) < w_start + non_ant_time
                next_t = to_time_slice(m; t=ind.t + w_length)
                next_inds = indices(m; ind..., t=next_t)
                if !isempty(next_inds)
                    next_ind = first(next_inds)
                    if non_ant_margin != nothing
                        lb = val[next_ind] - non_ant_margin
                        (lb < 0) && (lb = 0)
                        set_lower_bound(var[ind], lb)
                        ub = val[next_ind] + non_ant_margin
                        set_upper_bound(var[ind], ub)
                    else                    
                        fix(var[ind], val[next_ind]; force=true)
                    end
                end
            end
        end
    end
end

function unfix_history!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        var = m.ext[:spineopt].variables[name]
        indices = definition[:indices]
        for history_ind in indices(m; t=history_time_slice(m))
            _unfix(var[history_ind])
        end
    end
end

_unfix(v::VariableRef) = is_fixed(v) && unfix(v)
_unfix(::Call) = nothing
