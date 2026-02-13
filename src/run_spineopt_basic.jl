#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

function do_run_spineopt!(
    m,
    url_out,
    ::Val{:basic_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    build_model!(m; log_level)
    optimize || return m
    try
        solve_model!(m; log_level, update_names, write_as_roll, resume_file_path)
        if write_as_roll > 0
            _write_intermediate_results(m)
        else
            write_report(m, url_out; alternative, log_level)
        end
        m
    catch err
        showerror(stdout, err, catch_backtrace())
        m
    finally
        if write_as_roll > 0
            write_report_from_intermediate_results(m, url_out; alternative, log_level)
        end
    end
end

function _set_value_translator()
    vals = shared_values(model=first(model()), _strict=false)
    translator = vals === nothing ? nothing : v -> get(vals, v, nothing)
    set_value_translator(translator)
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
    num_variables(m) == 0 || return
    _generate_reports_by_output!(m)
    t_start = now()
    @log log_level 1 "\nBuild started at $t_start"
    model_name = _model_name(m)
    @timelog log_level 2 "Creating $model_name temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating $model_name stochastic structure..." generate_stochastic_structure!(m)
    !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) &&
        @timelog log_level 2 "Creating $model_name economic structure..." generate_economic_structure!(m)
    roll_count = m.ext[:spineopt].temporal_structure[:window_count] - 1
    roll_temporal_structure!(m, 1:roll_count)
    @timelog log_level 2 "Adding $model_name independent variables...\n" _add_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding $model_name dependent variables...\n" _add_dependent_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding $model_name expressions...\n" _add_expressions!(m; log_level=log_level)
    @timelog log_level 2 "Adding $model_name constraints...\n" _add_constraints!(m; log_level=log_level)
    @timelog log_level 2 "Setting $model_name objective..." _set_objective!(m)
    _init_outputs!(m)
    _call_event_handlers(m, :model_built)
    _is_benders_subproblem(m) && _build_mp_model!(master_model(m); log_level=log_level)
    t_end = now()
    elapsed_time_string = _elapsed_time_string(t_start, t_end)
    @log log_level 1 "Build complete. Started at $t_start, ended at $t_end, elapsed time: $elapsed_time_string"
    get!(m.ext[:spineopt].extras, :build_time, Dict())[(model=model_name,)] = elapsed_time_string
    _build_stage_models!(m; log_level)
end

function _generate_reports_by_output!(m)
    reports_by_output = m.ext[:spineopt].reports_by_output
    empty!(reports_by_output)
    instance = m.ext[:spineopt].instance
    stage = m.ext[:spineopt].stage
    if stage === nothing
        for rpt in model__report(model=instance)
            for out in report__output(report=rpt)
                output_key = (out.name, overwrite_results_on_rolling(report=rpt, output=out))
                push!(get!(reports_by_output, output_key, []), rpt.name)
            end
        end
    else
        outputs = (
            out
            for stage__output__entity in (stage__output__unit, stage__output__node, stage__output__connection)
            for (out, _ent) in stage__output__entity(stage=stage)
        )
        for out in Iterators.flatten((outputs, stage__output(stage=stage)))
            reports_by_output[out.name, true] = []
        end
    end
end

"""
Add SpineOpt variables to the given model.
"""
function _add_variables!(m; log_level=3)
    for add_variable! in (
            add_variable_binary_gas_connection_flow!,
            add_variable_connection_flow!,
            add_variable_connection_intact_flow!,
            add_variable_connections_decommissioned!,
            add_variable_connections_invested!,
            add_variable_connections_invested_available!,
            add_variable_min_capacity_margin_slack!,
            add_variable_node_injection!,
            add_variable_node_pressure!,
            add_variable_node_slack_neg!,
            add_variable_node_slack_pos!,
            add_variable_node_state!,
            add_variable_node_voltage_angle!,
            add_variable_nonspin_units_shut_down!,
            add_variable_nonspin_units_started_up!,
            add_variable_storages_decommissioned!,
            add_variable_storages_invested!,
            add_variable_storages_invested_available!,
            add_variable_unit_flow!,
            add_variable_unit_flow_op!,
            add_variable_unit_flow_op_active!,
            add_variable_units_invested!,
            add_variable_units_invested_available!,
            add_variable_units_mothballed!,
            add_variable_units_on!,
            add_variable_units_out_of_service!,
            add_variable_units_returned_to_service!,
            add_variable_units_shut_down!,
            add_variable_units_started_up!,
            add_variable_units_taken_out_of_service!,
            add_variable_user_constraint_slack_neg!,
            add_variable_user_constraint_slack_pos!,
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
            add_constraint_candidate_connection_flow_lb!,
            add_constraint_candidate_connection_flow_ub!,
            add_constraint_compression_ratio!,
            add_constraint_connection_flow_capacity!,
            add_constraint_connection_flow_gas_capacity!,
            add_constraint_connection_flow_intact_flow!,
            add_constraint_connection_flow_lodf!,
            add_constraint_connection_intact_flow_capacity!,
            add_constraint_connection_intact_flow_ptdf!,
            add_constraint_connection_lifetime!,
            add_constraint_connection_min_flow!,
            add_constraint_connection_unitary_gas_flow!,
            add_constraint_connections_invested_available!,
            add_constraint_connections_invested_transition!,
            add_constraint_cyclic_node_state!,
            add_constraint_fix_node_pressure_point!,
            add_constraint_fix_ratio_in_in_unit_flow!,
            add_constraint_fix_ratio_in_out_unit_flow!,
            add_constraint_fix_ratio_out_in_connection_flow!,
            add_constraint_fix_ratio_out_in_unit_flow!,
            add_constraint_fix_ratio_out_out_unit_flow!,
            add_constraint_investment_group_equal_investments!,
            add_constraint_investment_group_maximum_capacity_invested_available!,            
            add_constraint_investment_group_maximum_entities_invested_available!,
            add_constraint_investment_group_minimum_capacity_invested_available!,
            add_constraint_investment_group_minimum_entities_invested_available!,
            add_constraint_max_node_pressure!,
            add_constraint_max_node_voltage_angle!,
            add_constraint_max_ratio_in_in_unit_flow!,
            add_constraint_max_ratio_in_out_unit_flow!,
            add_constraint_max_ratio_out_in_connection_flow!,
            add_constraint_max_ratio_out_in_unit_flow!,
            add_constraint_max_ratio_out_out_unit_flow!,
            add_constraint_max_total_cumulated_unit_flow_from_node!,
            add_constraint_max_total_cumulated_unit_flow_to_node!,
            add_constraint_min_capacity_margin!,
            add_constraint_min_down_time!,
            add_constraint_min_node_pressure!,
            add_constraint_min_node_voltage_angle!,
            add_constraint_min_ratio_in_in_unit_flow!,
            add_constraint_min_ratio_in_out_unit_flow!,
            add_constraint_min_ratio_out_in_connection_flow!,
            add_constraint_min_ratio_out_in_unit_flow!,
            add_constraint_min_ratio_out_out_unit_flow!,
            add_constraint_min_scheduled_outage_duration!,
            add_constraint_min_total_cumulated_unit_flow_from_node!,
            add_constraint_min_total_cumulated_unit_flow_to_node!,
            add_constraint_min_up_time!,
            add_constraint_minimum_operating_point!,
            add_constraint_nodal_balance!,
            add_constraint_node_injection!,
            add_constraint_node_state_capacity!,
            add_constraint_min_node_state!,
            add_constraint_node_voltage_angle!,
            add_constraint_non_spinning_reserves_lower_bound!,
            add_constraint_non_spinning_reserves_shut_down_upper_bound!,
            add_constraint_non_spinning_reserves_start_up_upper_bound!,
            add_constraint_operating_point_bounds!,
            add_constraint_operating_point_rank!,
            add_constraint_ramp_down!,
            add_constraint_ramp_up!,
            add_constraint_ratio_out_in_connection_intact_flow!,            
            add_constraint_storage_lifetime!,
            add_constraint_storage_line_pack!,
            add_constraint_storages_invested_available!,
            add_constraint_storages_invested_transition!,
            add_constraint_unit_flow_capacity!,
            add_constraint_unit_flow_op_bounds!,
            add_constraint_unit_flow_op_rank!,
            add_constraint_unit_flow_op_sum!,
            add_constraint_unit_lifetime!,
            add_constraint_unit_state_transition!,
            add_constraint_units_available!,
            add_constraint_units_invested_available!,
            add_constraint_units_invested_transition!,
            add_constraint_units_out_of_service_contiguity!,
            add_constraint_units_out_of_service_transition!,
            add_constraint_user_constraint!,
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
    middle_history = history_time_slice(m; temporal_block=temporal_block(has_free_start=true))
    setdiff!(beyond_window, middle_history)
    setdiff!(in_window, middle_history)
    filter!(t -> !(t in in_window), beyond_window)
    for term in objective_terms(m; benders_master=!_is_benders_subproblem(m))
        func = getproperty(SpineOpt, term)
        m.ext[:spineopt].objective_terms[term] = (func(m, in_window), func(m, beyond_window))
    end
end

function _init_outputs!(m::Model)
    for out_name in _output_names(m)
        get!(m.ext[:spineopt].outputs, out_name, Dict())
    end
end

function _build_stage_models!(m; log_level)
    for (st, stage_m) in m.ext[:spineopt].model_by_stage
        with_env(stage_scenario(stage=st)) do
            build_model!(stage_m; log_level)
        end
        child_models = _child_models(m, st)
        model_name = _model_name(stage_m)
        @timelog log_level 2 "Initializing outputs for $model_name..." _init_downstream_outputs!(
            st, stage_m, child_models
        )
    end
end

function _init_downstream_outputs!(st, stage_m, child_models)
    for (out_name, _ow) in keys(stage_m.ext[:spineopt].reports_by_output)
        out = output(out_name)
        out_indices = stage_m.ext[:spineopt].variables_definition[out_name][:indices](stage_m)
        isempty(out_indices) && continue
        objs_by_class_name = if out in stage__output(stage=st)
            Dict(:unit => anything, :node => anything, :connection => anything)
        else
            Dict(
                :unit => stage__output__unit(stage=st, output=out),
                :node => stage__output__node(stage=st, output=out),
                :connection => stage__output__connection(stage=st, output=out),
            )
        end
        unique_entities = unique(_drop_key(ind, :t) for ind in out_indices)
        filter!(unique_entities) do ent
            _stage_output_includes_entity(ent, objs_by_class_name)
        end
        isempty(unique_entities) && continue
        model_very_end = maximum(end_.(ind.t for ind in out_indices))
        # Since we take the `start` of the `TimeSlice` when saving outputs,
        # we initialize each output as a TimeSeries mapping the window very end plus 1 minute to NaN.
        # This allows the previous point (last actual data point) to stick till the end
        downstream_outputs = stage_m.ext[:spineopt].downstream_outputs[out_name] = Dict(
            ent => parameter_value(TimeSeries([model_very_end + Minute(1)], [NaN])) for ent in unique_entities
        )
        objs_by_class_name_by_res = Dict()
        for (class_name, objs) in objs_by_class_name
            if objs === anything
                res = output_resolution(; stage=st, output=out, _strict=false)
                get!(objs_by_class_name_by_res, res, Dict())[class_name] = anything
                continue
            end
            for obj in objs
                res = output_resolution(; stage=st, output=out, ((class_name => obj),)..., _strict=false)
                push!(get!(get!(objs_by_class_name_by_res, res, Dict()), class_name, []), obj)
            end
        end
        for (out_res, objs_by_class_name) in objs_by_class_name_by_res
            for child_m in child_models
                fix_points = _fix_points(out_res, child_m)
                fix_indices_by_ent = Dict()
                for ind in child_m.ext[:spineopt].variables_definition[out_name][:indices](child_m)
                    any(start(ind.t) <= fix_t <= end_(ind.t) for fix_t in fix_points) || continue
                    ent = _drop_key(ind, :t)
                    _stage_output_includes_entity(ent, objs_by_class_name) || continue
                    push!(get!(fix_indices_by_ent, ent, []), ind)
                end
                for (ent, fix_indices) in fix_indices_by_ent
                    input = downstream_outputs[ent]
                    penalty = slack_penalty(; stage=st, output=out, ent..., _strict=false)
                    slack_names = if penalty !== nothing
                        slack_names = (Symbol(join((st, out, slack), "_")) for slack in ("slack_pos", "slack_neg"))
                        for slack_name in slack_names
                            _add_slack_variables!(child_m, slack_name, fix_indices)
                        end
                        slack_names
                    end
                    for ind in fix_indices
                        call_kwargs = (analysis_time=_analysis_time(child_m), t=ind.t)
                        call = Call(input, call_kwargs, (Symbol(st.name, :_, out_name), call_kwargs))
                        var = child_m.ext[:spineopt].variables[out_name][ind]
                        if penalty === nothing
                            if var isa VariableRef
                                fix(var, call)
                            elseif var isa GenericAffExpr
                                set_expr_bound(var, ==, call)
                            end
                        else
                            slack_pos, slack_neg = (
                                child_m.ext[:spineopt].variables[slack_name][ind] for slack_name in slack_names
                            )
                            cons = get!(
                                child_m.ext[:spineopt].constraints, Symbol(join((st, out, "slack"), "_")), Dict()
                            )
                            cons[ind] = set_expr_bound(var + slack_pos - slack_neg, ==, call)
                            set_objective_coefficient(child_m, slack_pos, penalty)
                            set_objective_coefficient(child_m, slack_neg, penalty)
                        end
                    end
                end
            end
        end
    end
end

function _add_slack_variables!(child_m, slack_name, inds)
    child_m.ext[:spineopt].variables_definition[slack_name] = var_def = _variable_definition()
    var_def[:indices] = (m; kwargs...) -> inds
    child_m.ext[:spineopt].variables[slack_name] = Dict(
        ind => @variable(child_m, base_name=_base_name(slack_name, ind), lower_bound=0) for ind in inds
    )
end

function _stage_output_includes_entity(ent, objs_by_class_name)
    any(objs_by_class_name) do (class_name, objs)
        obj = get(ent, class_name, nothing)
        obj !== nothing && obj in objs
    end
end

# If output_resolution is not specified, just fix the window end
_fix_points(::Nothing, child_m) = (maximum(end_.(time_slice(child_m))),)
function _fix_points(out_res, child_m)
    out_res_pv = parameter_value(out_res)
    w_start, w_end = minimum(start.(time_slice(child_m))), maximum(end_.(time_slice(child_m)))
    next_point = w_start
    points = Set()
    for i in Iterators.countfrom(1)
        res = out_res_pv(i=i)
        res === nothing && break
        if iszero(res)
            push!(points, w_end)
            break
        end
        next_point += res
        next_point > w_end && break
        push!(points, next_point)
    end
    points
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
"""
function solve_model!(
    m;
    log_level=3,
    update_names=false,
    write_as_roll=0,
    resume_file_path=nothing,
    output_suffix=(;),
    log_prefix="",
)
    m_mp = master_model(m)
    calculate_duals = any(
        startswith(name, r"bound_|constraint_") for name in lowercase.(string.(keys(m.ext[:spineopt].outputs)))
    )
    if m_mp === nothing
        # Standard solution method
        _do_solve_multi_stage_model!(
            m; log_level, update_names, write_as_roll, resume_file_path, output_suffix, log_prefix, calculate_duals
        )
    else
        # Benders solution method
        _init_benders_invested_available!(m_mp, m)
        add_event_handler!(process_subproblem_solution, m, :window_solved)
        add_event_handler!(_set_starting_point!, m, :window_about_to_solve)
        add_event_handler!(m, :window_solved) do m, k
            _save_result!(m, k; filter_accepts_variable=(name -> !occursin("invested", string(name))))
        end
        m_mp.ext[:spineopt].temporal_structure[:sp_windows] = m.ext[:spineopt].temporal_structure[:windows]
        undo_force_starting_investments! = _force_starting_investments!(m_mp)
        min_benders_iterations = min_iterations(model=m_mp.ext[:spineopt].instance)
        max_benders_iterations = max_iterations(model=m_mp.ext[:spineopt].instance)
        for j in Iterators.countfrom(1)
            @log log_level 0 "\nStarting Benders iteration $j"
            j == 2 && undo_force_starting_investments!()
            extra_kwargs = if report_benders_iterations(model=m_mp.ext[:spineopt].instance)
                (save_outputs=true, output_suffix=(output_suffix..., benders_iteration=current_bi,))
            else
                (save_outputs=false, output_suffix=output_suffix)
            end
            _do_solve_model!(m_mp; log_level, update_names, log_prefix, extra_kwargs...) || return false
            @timelog log_level 2 "Processing $(_model_name(m_mp)) solution" process_master_problem_solution(m_mp, m)
            _do_solve_multi_stage_model!(
                m;
                log_level,
                update_names,
                calculate_duals=true,
                log_prefix="$(log_prefix)Benders iteration $j $(_current_solution_string(m_mp)) - ",
                extra_kwargs...,
            ) || return false
            @timelog log_level 2 "Computing benders gap..." save_mp_objective_bounds_and_gap!(m_mp, m)
            @log log_level 1 "Benders iteration $j complete"
            @log log_level 1 "Objective lower bound: $(_lb_str(m_mp))"
            @log log_level 1 "Objective upper bound: $(_ub_str(m_mp))"
            @log log_level 1 "Gap: $(_gap_str(m_mp))"
            gap = last(m_mp.ext[:spineopt].benders_gaps)
            termination_msg = if gap <= max_gap(model=m_mp.ext[:spineopt].instance) && j >= min_benders_iterations
                "Benders tolerance satisfied at iter $j"
            elseif j >= max_benders_iterations
                "Maximum number of Benders iterations reached ($j)"
            end
            if termination_msg !== nothing
                @log log_level 1 termination_msg
                if !report_benders_iterations(model=m_mp.ext[:spineopt].instance)
                    final_log_prefix = string(
                        log_prefix, "$termination_msg $(_current_solution_string(m_mp)) - collecting outputs - "
                    )
                    _collect_outputs!(
                        m,
                        m_mp;
                        log_level,
                        update_names,
                        write_as_roll,
                        output_suffix,
                        calculate_duals,
                        log_prefix=final_log_prefix,
                    )
                end
                break
            end
            @timelog log_level 2 "Add MP cuts..." _add_mp_cuts!(m_mp, m; log_level=log_level)
            unfix_history!(m)
            global current_bi = add_benders_iteration(j + 1)
        end
        true
    end
end

function _do_solve_multi_stage_model!(
    m;
    log_level=3,
    update_names=false,
    write_as_roll=0,
    resume_file_path=nothing,
    output_suffix=(;),
    log_prefix="",
    calculate_duals=false,
    save_outputs=true,
)
    _solve_stage_models!(m; log_level, log_prefix, output_suffix) || return false
    _do_solve_model!(
        m;
        log_level,
        update_names,
        write_as_roll,
        resume_file_path,
        output_suffix,
        log_prefix,
        calculate_duals,
        save_outputs,
    )
end

function _solve_stage_models!(m; log_level, kwargs...)
    for stage_m in values(m.ext[:spineopt].model_by_stage)
        _do_solve_model!(stage_m; log_level, kwargs...) || return false
        model_name = _model_name(stage_m)
        @timelog log_level 2 "Updating outputs for $model_name..." _update_downstream_outputs!(stage_m)
    end
    true
end

function _do_solve_model!(
    m;
    log_level=3,
    update_names=false,
    write_as_roll=0,
    resume_file_path=nothing,
    output_suffix=(;),
    log_prefix="",
    calculate_duals=false,
    save_outputs=true,
    skip_failed_windows=false,
)
    k0 = _resume_run!(m, resume_file_path; log_level, update_names)
    k0 === nothing && return true
    _call_event_handlers(m, :model_about_to_solve)
    m.ext[:spineopt].has_results[] && return true
    t_start = now()
    @log log_level 1 "\nSolve started at $t_start"
    model_name = _model_name(m)
    full_model_name = string(log_prefix, model_name)
    if m.ext[:spineopt].temporal_structure[:as_number_or_call] === as_call
        @timelog log_level 2 "Bringing $model_name to the first window..." rewind_temporal_structure!(m)
    end
    stats = Dict()
    for k in Iterators.countfrom(k0)
        @log log_level 1 "\n$full_model_name - window $k of $(window_count(m)): $(current_window(m))"
        _call_event_handlers(m, :window_about_to_solve, k)
        if !m.ext[:spineopt].has_results[]
            if optimize_model!(
                m; log_level, output_suffix, calculate_duals, save_outputs, stats, print_conflict=!skip_failed_windows
            )
                _call_event_handlers(m, :window_solved, k)
            elseif skip_failed_windows
                @error "$full_model_name - window $k failed to solve! - you might see a gap in the results"
                _call_event_handlers(m, :window_failed, k)
                unfix_history!(m)
            else
                return false
            end
        end
        _save_window_state(m, k; write_as_roll, resume_file_path)
        if @timelog log_level 2 "Rolling $model_name temporal structure..." stats !roll_temporal_structure!(m, k)
            @log log_level 2 "Rolling complete\n"
            m.ext[:spineopt].has_results[] = false
            break
        end
        update_model!(m; log_level, update_names, stats)
        m.ext[:spineopt].has_results[] = false
    end
    _call_event_handlers(m, :model_solved)
    t_end = now()
    elapsed_time_string = _elapsed_time_string(t_start, t_end)
    @log log_level 1 "Solve complete. Started at $t_start, ended at $t_end, elapsed time: $elapsed_time_string"
    if log_level >= 2
        rows = [["Action", "min", "max", "avg"]]
        for (action, times) in stats
            min, max = string.(extrema(times))
            avg = string(sum(times) / length(times))
            push!(rows, [action, min, max, avg])
        end
        println("Time summary:")
        _print_table(rows)
    end
    solve_name = (; model=model_name, output_suffix...)
    get!(m.ext[:spineopt].extras, :solve_time, Dict())[solve_name] = elapsed_time_string
    true
end

function _print_table(rows)
    widths = [maximum(length.([r[j] for r in rows])) for j in 1:4]
    println()
    _print_row(rows[1], widths)
    _print_hline(widths)
    for row in rows[2:end]
        _print_row(row, widths)
    end
    println()
end

function _print_hline(widths)
    row = [repeat("─", w) for w in widths]
    _print_row(row, widths, "─┼─")
end

function _print_row(row, widths, delim=" │ ")
    for (j, x) in enumerate(row)
        print(rpad(x, widths[j]))
        j != length(row) && print(delim)
    end
    println()
end

function _update_downstream_outputs!(stage_m)
    for (out_name, current_downstream_outputs) in stage_m.ext[:spineopt].downstream_outputs
        new_downstream_outputs = Dict(
            ent => parameter_value(val)
            for (ent, val) in _output_value_by_entity(
                stage_m.ext[:spineopt].outputs[out_name], model_end(model=stage_m.ext[:spineopt].instance)
            )
        )
        mergewith!(merge!, current_downstream_outputs, new_downstream_outputs)
    end
end

function _child_models(m, st)
    child_models = [m.ext[:spineopt].model_by_stage[child_st] for child_st in stage__child_stage(stage1=st)]
    if isempty(child_models)
        child_models = [m]
    end
    child_models
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
    history_time_slices = m.ext[:spineopt].variables_definition[name][:history_time_slices]
    m.ext[:spineopt].values[name] = Dict(
        ind => values[string(name)][string(ind)]
        for ind in indices(m; t=vcat(history_time_slices, time_slice(m)), temporal_block=anything)
    )
end

"""
Optimize the given model.
If an optimal solution is found, save results and return `true`, otherwise return `false`.
"""
function optimize_model!(
    m::Model;
    log_level=3,
    calculate_duals=false,
    output_suffix=(;),
    save_outputs=true,
    print_conflict=true,
    stats=nothing,
)
    write_mps_file(model=m.ext[:spineopt].instance) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section.
    model_name = _model_name(m)
    @timelog log_level 0 "Optimizing $model_name..." stats optimize!(m)
    termination_st = termination_status(m)
    if termination_st in (MOI.OPTIMAL, MOI.TIME_LIMIT)
        if result_count(m) > 0
            solution_type = termination_st == MOI.OPTIMAL ? "Optimal" : "Feasible"
            @log log_level 1 "$solution_type solution found, objective function value: $(objective_value(m))"
            m.ext[:spineopt].has_results[] = true
            @timelog log_level 2 "Saving $model_name results..." stats _save_model_results!(m)
            calculate_duals && _calculate_duals(m; log_level=log_level)
            if save_outputs
                @timelog log_level 2 "Postprocessing $model_name results..." stats postprocess_results!(m)
                @timelog log_level 2 "Saving $model_name outputs..." stats _save_outputs!(m, output_suffix)
            end
        else
            m.ext[:spineopt].has_results[] = false
            @warn "no solution available for $model_name - window $(current_window(m)) - moving on..."
        end
        true
    elseif termination_st == MOI.INFEASIBLE && print_conflict
        printstyled(
            string(
                "model $model_name is infeasible - ",
                "if conflicting constraints can be identified, they will be reported below\n",
            );
            bold=true,
        )
        try
            _compute_and_print_conflict!(m)
        catch err
            @info err.msg
        end
        false
    else
        @log log_level 0 "Unable to find solution for $model_name (reason: $(termination_status(m)))"
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
    _save_expression_values!(m)
    _save_constraint_values!(m)
    _save_objective_values!(m)
    _save_other_values!(m)
end

"""
Save the value of all variables in a model.
"""
function _save_variable_values!(m::Model)
    for (name, vars) in m.ext[:spineopt].variables
        inds = if haskey(m.ext[:spineopt].outputs, name) || !haskey(m.ext[:spineopt].variables_definition, name)
            keys(vars)
        else
            keys(m.ext[:spineopt].variables_definition[name][:history_vars_by_ind])
        end
        m.ext[:spineopt].values[name] = _fdict(_variable_value, inds, (vars[ind] for ind in inds))
    end
end

"""
The value of a JuMP variable, rounded if necessary.
"""
_variable_value(v::VariableRef) = (is_integer(v) || is_binary(v)) ? round(Int, JuMP.value(v)) : JuMP.value(v)
_variable_value(e::AffExpr) = value(e)
_variable_value(x::GenericAffExpr{Call,VariableRef}) = value(realize(x))

function _save_expression_values!(m::Model)
    for (name, exprs) in m.ext[:spineopt].expressions
        name in keys(m.ext[:spineopt].outputs) || continue
        m.ext[:spineopt].values[name] = _fdict(JuMP.value, exprs)
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
    for (name, cons) in m.ext[:spineopt].constraints
        name = Symbol(:value_constraint_, name)
        name in keys(m.ext[:spineopt].outputs) || continue
        m.ext[:spineopt].values[name] = _fdict(JuMP.value, cons)
    end
end

"""
A copy of given dictionary `d` computed by applying the given function `f` to each value.
"""
function _fdict(f, d)
    _fdict(f, keys(d), values(d))
end
function _fdict(f, k, v)
    vals = collect(Any, v)
    @Threads.threads for i in eachindex(vals)
        vals[i] = f(vals[i])
    end
    Dict(zip(k, vals))
end

"""
Save the value of the objective terms in a model.
"""
function _save_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    total_costs = total_costs_tail = 0
    needs_total_costs = _is_benders_subproblem(m) || haskey(m.ext[:spineopt].outputs, :total_costs)
    for (term, (in_window, beyond_window)) in m.ext[:spineopt].objective_terms
        needs_term = term in keys(m.ext[:spineopt].outputs)
        needs_total_costs || needs_term || continue
        cost = JuMP.value(realize(in_window))
        if needs_term
            m.ext[:spineopt].values[term] = Dict(ind => cost)
        end
        if needs_total_costs
            cost_tail = JuMP.value(realize(beyond_window))
            total_costs += cost
            total_costs_tail += cost_tail
        end
    end
    if needs_total_costs
        m.ext[:spineopt].values[:total_costs] = Dict(ind => total_costs)
        m.ext[:spineopt].values[:total_costs_tail] = Dict(ind => total_costs_tail)
    end
end

function _save_window_state(m, k; write_as_roll, resume_file_path)
    if write_as_roll > 0 && k % write_as_roll == 0
        _write_intermediate_results(m)
        _dump_resume_data(m, k, resume_file_path)
        _clear_results!(m)
    end
end

function _calculate_duals(m; log_level=3)
    model_name = _model_name(m)
    if has_duals(m)
        _save_marginal_values!(m)
        _save_bound_marginal_values!(m)
    elseif _is_benders_subproblem(m)
        @log log_level 1 "Obtaining duals for $model_name to generate Benders cuts..."
        _calculate_duals_fallback(m; log_level=log_level, for_benders=true)
    else
        @log log_level 1 "Obtaining duals for $model_name..."
        _calculate_duals_cplex(m; log_level=log_level) && return
        _calculate_duals_fallback(m; log_level=log_level)
    end
end

function _calculate_duals_cplex(m; log_level=3)
    CPLEX = Base.invokelatest(get_module, :CPLEX)
    CPLEX === nothing && return false
    cplex_model = _get_cplex_model(m)
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

function _get_cplex_model(m)
    model_backend = backend(m)
    cplex_optimizer = JuMP.mode(m) == JuMP.DIRECT ? model_backend : model_backend.optimizer
    if hasproperty(cplex_optimizer, :model)
        cplex_optimizer.model
    else
        cplex_optimizer
    end
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
    @timelog log_level 1 "Copying model..." (m_dual_lp, ref_map) = copy_model(m)
    set_optimizer(m_dual_lp, m.ext[:spineopt].lp_solver)
    @log log_level 1 "Set LP solver $(solver_name(m_dual_lp)) for the copy."
    fix_variables = if for_benders
        (:units_invested_available, :connections_invested_available, :storages_invested_available)
    else
        ()
    end
    @timelog log_level 1 "Relaxing discrete variables..." _relax_discrete_vars!(m, ref_map; fix_variables)
    dual_fallback(con) = DualPromise(ref_map[con])
    reduced_cost_fallback(var) = ReducedCostPromise(ref_map[var])
    _save_marginal_values!(m, dual_fallback)
    _save_bound_marginal_values!(m, reduced_cost_fallback)
    if isdefined(Threads, Symbol("@spawn")) && Threads.nthreads() > 1
    # `Threads.@spawn` only since Julia v1.3. Only attempt parallelization if multiple threads are in use to avoid issues.
        #TODO: This command would suspend the running of `m = run_spineopt(...; optimize=true, ...)`
        # in the unit test `run_spineopt_representative_periods.jl`. Suspension comes at launching the `optimize!()`.
        # Add an arbitraty command, either before or after this command, could shift the suspension 
        # to the completion of the `optimize!()`.
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

function _relax_discrete_vars!(m::Model, ref_map::ReferenceMap; fix_variables=())
    for (name, var_by_ind) in m.ext[:spineopt].variables
        def = m.ext[:spineopt].variables_definition[name]
        def[:bin] === def[:int] === nothing && continue
        for var in values(var_by_ind)
            var isa VariableRef || continue
            ref_var = ref_map[var]
            if is_binary(ref_var)
                unset_binary(ref_var)
            elseif is_integer(ref_var)
                unset_integer(ref_var)
            else
                continue
            end
            if name in fix_variables || isempty(fix_variables)
                val = _variable_value(var)
                fix(ref_var, val; force=true)
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
function _save_outputs!(m, output_suffix)
    _do_save_outputs!(m, _output_names(m), output_suffix)
end

function _do_save_outputs!(m, output_names, output_suffix; weight=1)
    w_start, w_end = start(current_window(m)), end_(current_window(m))
    for out_name in output_names
        value = get(m.ext[:spineopt].values, out_name, nothing)
        param = parameter(out_name, @__MODULE__)
        if value === param === nothing
            @warn "can't find any values for '$out_name'"
            continue
        end
        by_suffix = get!(m.ext[:spineopt].outputs, out_name, Dict())
        by_window = get!(by_suffix, output_suffix, Dict())
        by_window[w_start, w_end] = Dict(Iterators.map(((ind, val),) ->
            (_static(ind), weight * val), _output_value_by_ind(m, something(value, param))))
    end
end

_static(ind::NamedTuple) = NamedTuple{keys(ind)}(map(_static, values(ind)))
_static(t::TimeSlice) = (start(t), end_(t))
_static(x) = x

_output_value_by_ind(_m, value::Dict) = value
function _output_value_by_ind(m, parameter::Parameter)
    inds = (
        (; entity..., stochastic_scenario=scen, t=t)
        for entity in indices_as_tuples(parameter)
        for (scen, t) in stochastic_time_indices(m)
    )
    (
        (ind, val)
        for (ind, val) in (
            (ind, parameter(; ind..., analysis_time=start(current_window(m)), _strict=false)) for ind in inds
        )
        if val !== nothing
    )
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
    file_path = joinpath(m.ext[:spineopt].intermediate_results_folder, ".reports_by_output")
    if !isfile(file_path)
        @info """
        Intermediate results are being written to $(m.ext[:spineopt].intermediate_results_folder).

        These results will be cleared automatically when written to the DB.
        However if your run fails before this can happen, you can write them manually by running

            write_report_from_intermediate_results(raw"$(m.ext[:spineopt].intermediate_results_folder)", url_out)

        """
        open(file_path, "w") do f
            JSON.print(f, m.ext[:spineopt].reports_by_output)
        end
    end
    for (file_path, table) in tables
        isfile(file_path) ? Arrow.append(file_path, table) : Arrow.write(file_path, table; file=false)
    end
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
    reports_by_output = _reports_by_output(x)
    values = _collect_values_from_intermediate_results(intermediate_results_folder, reports_by_output)
    isempty(values) || write_report(
        reports_by_output, default_url, values; alternative=alternative, log_level=log_level
    )
    _clear_intermediate_results(x)
end

_intermediate_results_folder(m::Model) = m.ext[:spineopt].intermediate_results_folder
_intermediate_results_folder(intermediate_results_folder::AbstractString) = intermediate_results_folder

_reports_by_output(m::Model) = m.ext[:spineopt].reports_by_output
function _reports_by_output(intermediate_results_folder::AbstractString)
    JSON.parsefile(joinpath(intermediate_results_folder, ".reports_by_output"))
end

function _collect_values_from_intermediate_results(intermediate_results_folder, reports_by_output)
    values = Dict()
    for (output_name, overwrite) in keys(reports_by_output)
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
    isdir(path) || return
    try
        chmod(path, filemode(path) | 0o333)
    catch;
    end
    for (root, dirs, files) in walkdir(path; onerror=x->())
        for dir in dirs
            dpath = joinpath(root, dir)
            try
                chmod(dpath, filemode(dpath) | 0o333)
            catch;
            end
        end
    end
end

"""
    write_report(m, url_out; <keyword arguments>)

Write report(s) from given SpineOpt model to `url_out`.
A new Spine database is created at `url_out` if one doesn't exist.

# Arguments

- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.

- `log_level::Int=3`: an integer to control the log level.
"""
function write_report(m, url_out; alternative="", log_level=3)
    url_out === nothing && return
    values = _collect_all_output_values(m)
    write_report(m.ext[:spineopt].reports_by_output, url_out, values, alternative=alternative, log_level=log_level)
end
function write_report(reports_by_output::Dict, url_out, values::Dict; alternative="", log_level=3)
    for (report_name, vals) in _vals_by_report(reports_by_output, values)
        output_url = something(output_db_url(report=report(report_name), _strict=false), url_out)
        @timelog log_level 2 "Writing report to $output_url ..." write_parameters(
            vals, output_url; report=string(report_name), alternative=alternative, on_conflict="merge"
        )
    end
end

function _collect_all_output_values(m)
    m_mp = master_model(m)
    if m_mp === nothing
        _collect_output_values(m)
    else
        values_mp = _collect_output_values(m_mp)
        values = _collect_output_values(m)
        for key in (:total_costs, intersect(mp_terms, sp_terms)...)
            costs_keys = (k for k in keys(values_mp) if k[1] == key)
            costs_key = isempty(costs_keys) ? nothing : first(costs_keys)
            costs_mp = pop!(values_mp, costs_key, Dict())
            costs = pop!(values, costs_key, nothing)
            if costs !== nothing
                _merge(x, y) = timedata_operation(x, y) do x, y
                    sum(Iterators.filter(!isnan, (x, y)); init=0)
                end
                values_mp[costs_key] = merge!(_merge, costs_mp, costs)
            end
        end
        mergewith!(merge!, values_mp, values)
    end
end

function _vals_by_report(reports_by_output, values)
    vals_by_report = Dict()
    for ((output_name, overwrite), reports) in reports_by_output
        value = get(values, (output_name, overwrite), nothing)
        value === nothing && continue
        if output_name in all_objective_terms
            output_name = Symbol(:objective_, output_name)
        end
        for report_name in reports
            vals = get!(vals_by_report, report_name, Dict())
            vals[output_name] = value
        end
    end
    vals_by_report
end

function _collect_output_values(m)
    _wait_for_dual_solves(m)
    values = Dict()
    for (output_name, overwrite) in keys(m.ext[:spineopt].reports_by_output)
        by_suffix = get(m.ext[:spineopt].outputs, output_name, nothing)
        by_suffix === nothing && continue
        key = (output_name, overwrite)
        haskey(values, key) && continue
        out_res = output_resolution(output=output(output_name), stage=nothing)
        values[key] = _output_value_by_entity(by_suffix, model_end(model=m.ext[:spineopt].instance), overwrite, out_res)
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

function _output_value_by_entity(by_suffix, model_end, overwrite_results_on_rolling=true, output_resolution=nothing)
    d = Dict()
    for (suffix, by_window) in by_suffix
        for ((w_start, w_end), by_entity) in by_window
            crop_to_window = overwrite_results_on_rolling && w_end < model_end
            for (entity, value) in by_entity
                t_keys = [k for (k, v) in pairs(entity) if v isa Tuple{DateTime,DateTime}]
                t = t_start, t_end = isempty(t_keys) ? (w_start, w_end) : maximum(entity[k] for k in t_keys)
                t_start < w_start && continue
                crop_to_window && t_start >= w_end && continue
                entity = _output_entity(entity, t_keys, suffix)
                by_analysis_time = get!(d, entity, OrderedDict())
                by_t_interval = get!(by_analysis_time, w_start, OrderedDict())
                by_t_interval[t] = value
            end
        end
    end
    Dict(
        entity => _output_value(_polish!(by_analysis_time), overwrite_results_on_rolling, output_resolution)
        for (entity, by_analysis_time) in d
    )
end

function _output_entity(entity::NamedTuple, t_keys, suffix)
    stoch_path = get(entity, :stochastic_path, (;))
    flat_stoch_path = (; (Symbol(:stochastic_scenario, k) => scen for (k, scen) in enumerate(stoch_path))...)
    (; _drop_key(entity, :stochastic_path, t_keys...)..., flat_stoch_path..., suffix...)
end

function _polish!(by_analysis_time)
    OrderedDict(
        analysis_time => OrderedDict(
            t_start => realize(value) for ((t_start, t_end), value) in sort!(by_t_interval; lt=_t_interval_lt)
        )
        for (analysis_time, by_t_interval) in sort!(by_analysis_time)
    )
end

"""
Return true either if the first interval starts before the second,
or if it has a lower resolution (i.e. longer duration) than the second.
"""
function _t_interval_lt(t1, t2)
    t_start1, t_end1 = t1
    t_start2, t_end2 = t2
    t_start1 < t_start2 || t_end1 - t_start1 > t_end2 - t_start2
end

function _output_value(by_analysis_time, overwrite_results_on_rolling::Bool=true, output_resolution=nothing)
    _output_value(by_analysis_time, Val(overwrite_results_on_rolling), output_resolution)
end
function _output_value(by_analysis_time, overwrite_results_on_rolling::Val{true}, output_resolution)
    by_time_stamp = ((t, val) for by_time_stamp in values(by_analysis_time) for (t, val) in by_time_stamp)
    _aggregated(first.(by_time_stamp), collect(Float64, last.(by_time_stamp)), output_resolution; merge_ok=true)
end
function _output_value(by_analysis_time, overwrite_results_on_rolling::Val{false}, output_resolution)
    Map(
        collect(keys(by_analysis_time)),
        [
            _aggregated(collect(keys(by_time_stamp)), collect(Float64, values(by_time_stamp)), output_resolution)
            for by_time_stamp in values(by_analysis_time)
        ],
    )
end

_aggregated(inds, vals, ::Nothing; kwargs...) = TimeSeries(inds, vals; kwargs...)
function _aggregated(inds, vals, res; kwargs...)
    aggr_inds = []
    aggr_vals = []
    aggregate(ref_t, cumm_vals) = (push!(aggr_inds, ref_t); push!(aggr_vals, sum(cumm_vals) / length(cumm_vals)))
    ref_t = first(inds)
    cumm_vals = [first(vals)]
    for (t, v) in Iterators.drop(zip(inds, vals), 1)
        if t - ref_t < res
            # Accummulate
            push!(cumm_vals, v)
        else
            aggregate(ref_t, cumm_vals)
            ref_t = t
            cumm_vals = [v]
        end
    end
    if !isempty(cumm_vals)
        aggregate(ref_t, cumm_vals)
    end
    TimeSeries(aggr_inds, aggr_vals; kwargs...)
end

function _dump_resume_data(m::Model, k, ::Nothing) end
function _dump_resume_data(m::Model, k, resume_file_path)
    resume_data = Dict("values" => m.ext[:spineopt].values, "window" => k)
    open(resume_file_path, "w") do f
        JSON.print(f, resume_data, 4)
    end
end

function _clear_results!(m)
    for by_entity in values(m.ext[:spineopt].outputs)
        empty!(by_entity)
    end
end

"""
Update the given model for the next window in the rolling horizon: update variables, fix the necessary variables,
update constraints and update objective.
"""
function update_model!(m; log_level=3, update_names=false, stats=nothing)
    model_name = _model_name(m)
    if update_names
        @timelog log_level 2 "Updating $model_name variable names..." stats _update_variable_names!(m)
        @timelog log_level 2 "Updating $model_name constraint names..." stats _update_constraint_names!(m)
    end
    m.ext[:spineopt].has_results[] || return
    @timelog log_level 2 "Fixing $model_name history..." stats _fix_history!(m)
    @timelog log_level 2 "Applying $model_name non-anticipativity constraints..." stats begin
        apply_non_anticipativity_constraints!(m)
    end
end

function _update_variable_names!(m, names=keys(m.ext[:spineopt].variables))
    for name in names   
        var = m.ext[:spineopt].variables[name]
        history_time_slices = m.ext[:spineopt].variables_definition[name][:history_time_slices]
        # NOTE: only update names for the representative variables
        # This is achieved by using the indices function from the variable definition
        for ind in m.ext[:spineopt].variables_definition[name][:indices](m; t=[time_slice(m); history_time_slices])
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
_set_name(x, name) = nothing

function _fix_history!(m::Model)
    for (name, definition) in m.ext[:spineopt].variables_definition
        _fix_history_variable!(m, name, definition[:history_vars_by_ind])
    end
end

function _fix_history_variable!(m::Model, name::Symbol, history_vars_by_ind)
    vals = m.ext[:spineopt].values[name]
    for (ind, history_vars) in history_vars_by_ind
        _force_fix.(history_vars, vals[ind])
    end
end

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
            if !isnothing(non_ant_time) && start(ind.t) < w_start + non_ant_time
                next_t = to_time_slice(m; t=ind.t + w_length)
                next_inds = indices(m; ind..., t=next_t)
                if !isempty(next_inds)
                    next_ind = first(next_inds)
                    if !isnothing(non_ant_margin)
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
    m.ext[:spineopt].temporal_structure[:as_number_or_call] === as_number && return
    for (name, definition) in m.ext[:spineopt].variables_definition
        _unfix.(Iterators.flatten(values(definition[:history_vars_by_ind])))
    end
end

_unfix(v::VariableRef) = is_fixed(v) && unfix(v)
_unfix(::Call) = nothing
