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
    write_as_roll=0,
    resume_file_path=nothing
)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m)
    roll_count = _roll_count(m)
    @log log_level 2 """
    NOTE: We will first build the model for the last optimisation window to make sure it can roll that far.
    Then we will bring the model to the first window to start solving it.
    """
    roll_temporal_structure!(m, roll_count)
    init_model!(
        m;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        log_level=log_level,
        alternative_objective=alternative_objective
    )
    @timelog log_level 2 "Bringing model to the first window..." roll_temporal_structure!(m, -roll_count)
    try
        run_spineopt_kernel!(
            m,
            url_out;
            update_constraints=update_constraints,
            log_level=log_level,
            optimize=optimize,
            update_names=update_names,
            alternative=alternative,
            write_as_roll=write_as_roll,
            resume_file_path=resume_file_path,
        )
    catch err
        showerror(stdout, err, catch_backtrace())
        m
    finally
        if write_as_roll > 0
            write_report_from_intermediate_results(m, url_out; alternative=alternative, log_level=log_level)
        end
    end
end

function _roll_count(m::Model)
    instance = m.ext[:spineopt].instance
    roll_forward_ = roll_forward(model=instance, _strict=false)
    roll_forward_ in (nothing, 0) && return 0
    current_window_end = end_(current_window(m))
    roll_count = 0
    while current_window_end < model_end(model=instance)
        current_window_end += roll_forward_
        roll_count += 1
    end
    roll_count
end

"""
Initialize the given model for SpineOpt: add variables, fix the necessary variables, add constraints and set objective.
"""
function init_model!(
    m; add_user_variables=m -> nothing, add_constraints=m -> nothing, alternative_objective=m -> nothing, log_level=3
)
    @timelog log_level 2 "Adding variables...\n" _add_variables!(
        m; add_user_variables=add_user_variables, log_level=log_level
    )
    @timelog log_level 2 "Adding constraints...\n" _add_constraints!(
        m; add_constraints=add_constraints, log_level=log_level
    )
    @timelog log_level 2 "Setting objective..." _set_objective!(m; alternative_objective=alternative_objective)
    _init_outputs!(m)
end

"""
Add SpineOpt variables to the given model.
"""
function _add_variables!(m; add_user_variables=m -> nothing, log_level=3)
    for (name, add_variable!) in (
            ("units_available", add_variable_units_available!),
            ("units_on", add_variable_units_on!),
            ("units_started_up", add_variable_units_started_up!),
            ("units_shut_down", add_variable_units_shut_down!),
            ("unit_flow", add_variable_unit_flow!),
            ("unit_flow_op", add_variable_unit_flow_op!),
            ("unit_flow_op_active", add_variable_unit_flow_op_active!),
            ("connection_flow", add_variable_connection_flow!),
            ("connection_intact_flow", add_variable_connection_intact_flow!),
            ("connections_invested", add_variable_connections_invested!),
            ("connections_invested_available", add_variable_connections_invested_available!),
            ("connections_decommissioned", add_variable_connections_decommissioned!),
            ("storages_invested", add_variable_storages_invested!),
            ("storages_invested_available", add_variable_storages_invested_available!),
            ("storages_decommissioned", add_variable_storages_decommissioned!),
            ("node_state", add_variable_node_state!),
            ("node_slack_pos", add_variable_node_slack_pos!),
            ("node_slack_neg", add_variable_node_slack_neg!),
            ("node_injection", add_variable_node_injection!),
            ("units_invested", add_variable_units_invested!),
            ("units_invested_available", add_variable_units_invested_available!),
            ("units_mothballed", add_variable_units_mothballed!),
            ("ramp_up_unit_flow", add_variable_ramp_up_unit_flow!),
            ("start_up_unit_flow", add_variable_start_up_unit_flow!),
            ("nonspin_units_started_up", add_variable_nonspin_units_started_up!),
            ("nonspin_ramp_up_unit_flow", add_variable_nonspin_ramp_up_unit_flow!),
            ("ramp_down_unit_flow", add_variable_ramp_down_unit_flow!),
            ("shut_down_unit_flow", add_variable_shut_down_unit_flow!),
            ("nonspin_units_shut_down", add_variable_nonspin_units_shut_down!),
            ("nonspin_ramp_down_unit_flow", add_variable_nonspin_ramp_down_unit_flow!),
            ("node_pressure", add_variable_node_pressure!),
            ("node_voltage_angle", add_variable_node_voltage_angle!),
            ("binary_gas_connection_flow", add_variable_binary_gas_connection_flow!),
            ("user_defined", add_user_variables)
        )
        @timelog log_level 3 "- [variable_$name]" add_variable!(m)
    end
end

"""
Add SpineOpt constraints to the given model.
"""
function _add_constraints!(m; add_constraints=m -> nothing, log_level=3)
    for (name, add_constraint!) in (
            ("unit_pw_heat_rate", add_constraint_unit_pw_heat_rate!),
            ("user_constraint", add_constraint_user_constraint!),
            ("node_injection", add_constraint_node_injection!),
            ("nodal_balance", add_constraint_nodal_balance!),
            ("candidate_connection_flow_ub", add_constraint_candidate_connection_flow_ub!),
            ("candidate_connection_flow_lb", add_constraint_candidate_connection_flow_lb!),
            ("connection_intact_flow_ptdf", add_constraint_connection_intact_flow_ptdf!),
            ("connection_flow_intact_flow", add_constraint_connection_flow_intact_flow!),
            ("connection_flow_lodf", add_constraint_connection_flow_lodf!),
            ("connection_flow_capacity", add_constraint_connection_flow_capacity!),
            ("connection_intact_flow_capacity", add_constraint_connection_intact_flow_capacity!),
            ("unit_flow_capacity", add_constraint_unit_flow_capacity!),
            ("connections_invested_available", add_constraint_connections_invested_available!),
            ("connection_lifetime", add_constraint_connection_lifetime!),
            ("connections_invested_transition", add_constraint_connections_invested_transition!),
            ("storages_invested_available", add_constraint_storages_invested_available!),
            ("storage_lifetime", add_constraint_storage_lifetime!),
            ("storages_invested_transition", add_constraint_storages_invested_transition!),
            ("operating_point_bounds", add_constraint_operating_point_bounds!),
            ("operating_point_rank", add_constraint_operating_point_rank!),
            ("unit_flow_op_bounds", add_constraint_unit_flow_op_bounds!),
            ("unit_flow_op_rank", add_constraint_unit_flow_op_rank!),
            ("unit_flow_op_sum", add_constraint_unit_flow_op_sum!),
            ("fix_ratio_out_in_unit_flow", add_constraint_fix_ratio_out_in_unit_flow!),
            ("max_ratio_out_in_unit_flow", add_constraint_max_ratio_out_in_unit_flow!),
            ("min_ratio_out_in_unit_flow", add_constraint_min_ratio_out_in_unit_flow!),
            ("fix_ratio_out_out_unit_flow", add_constraint_fix_ratio_out_out_unit_flow!),
            ("max_ratio_out_out_unit_flow", add_constraint_max_ratio_out_out_unit_flow!),
            ("min_ratio_out_out_unit_flow", add_constraint_min_ratio_out_out_unit_flow!),
            ("fix_ratio_in_in_unit_flow", add_constraint_fix_ratio_in_in_unit_flow!),
            ("max_ratio_in_in_unit_flow", add_constraint_max_ratio_in_in_unit_flow!),
            ("min_ratio_in_in_unit_flow", add_constraint_min_ratio_in_in_unit_flow!),
            ("fix_ratio_in_out_unit_flow", add_constraint_fix_ratio_in_out_unit_flow!),
            ("max_ratio_in_out_unit_flow", add_constraint_max_ratio_in_out_unit_flow!),
            ("min_ratio_in_out_unit_flow", add_constraint_min_ratio_in_out_unit_flow!),
            ("ratio_out_in_connection_intact_flow", add_constraint_ratio_out_in_connection_intact_flow!),
            ("fix_ratio_out_in_connection_flow", add_constraint_fix_ratio_out_in_connection_flow!),
            ("max_ratio_out_in_connection_flow", add_constraint_max_ratio_out_in_connection_flow!),
            ("min_ratio_out_in_connection_flow", add_constraint_min_ratio_out_in_connection_flow!),
            ("node_state_capacity", add_constraint_node_state_capacity!),
            ("cyclic_node_state", add_constraint_cyclic_node_state!),
            ("max_total_cumulated_unit_flow_from_node", add_constraint_max_total_cumulated_unit_flow_from_node!),
            ("min_total_cumulated_unit_flow_from_node", add_constraint_min_total_cumulated_unit_flow_from_node!),
            ("max_total_cumulated_unit_flow_to_node", add_constraint_max_total_cumulated_unit_flow_to_node!),
            ("min_total_cumulated_unit_flow_to_node", add_constraint_min_total_cumulated_unit_flow_to_node!),
            ("units_on", add_constraint_units_on!),
            ("units_available", add_constraint_units_available!),
            ("units_invested_available", add_constraint_units_invested_available!),
            ("unit_lifetime", add_constraint_unit_lifetime!),
            ("units_invested_transition", add_constraint_units_invested_transition!),
            ("minimum_operating_point", add_constraint_minimum_operating_point!),
            ("min_down_time", add_constraint_min_down_time!),
            ("min_up_time", add_constraint_min_up_time!),
            ("unit_state_transition", add_constraint_unit_state_transition!),
            ("unit_flow_capacity_w_ramp", add_constraint_unit_flow_capacity_w_ramp!),
            ("split_ramps", add_constraint_split_ramps!),
            ("ramp_up", add_constraint_ramp_up!),
            ("max_start_up_ramp", add_constraint_max_start_up_ramp!),
            ("min_start_up_ramp", add_constraint_min_start_up_ramp!),
            ("max_nonspin_ramp_up", add_constraint_max_nonspin_ramp_up!),
            ("min_nonspin_ramp_up", add_constraint_min_nonspin_ramp_up!),
            ("ramp_down", add_constraint_ramp_down!),
            ("max_shut_down_ramp", add_constraint_max_shut_down_ramp!),
            ("min_shut_down_ramp", add_constraint_min_shut_down_ramp!),
            ("max_nonspin_ramp_down", add_constraint_max_nonspin_ramp_down!),
            ("min_nonspin_ramp_down", add_constraint_min_nonspin_ramp_down!),
            ("res_minimum_node_state", add_constraint_res_minimum_node_state!),
            ("fix_node_pressure_point", add_constraint_fix_node_pressure_point!),
            ("connection_unitary_gas_flow", add_constraint_connection_unitary_gas_flow!),
            ("compression_ratio", add_constraint_compression_ratio!),
            ("storage_line_pack", add_constraint_storage_line_pack!),
            ("connection_flow_gas_capacity", add_constraint_connection_flow_gas_capacity!),
            ("max_node_pressure", add_constraint_max_node_pressure!),
            ("min_node_pressure", add_constraint_min_node_pressure!),
            ("node_voltage_angle", add_constraint_node_voltage_angle!),
            ("max_node_voltage_angle", add_constraint_max_node_voltage_angle!),
            ("min_node_voltage_angle", add_constraint_min_node_voltage_angle!),
            ("user_defined", add_constraints),
        )
        @timelog log_level 3 "- [constraint_$name]" add_constraint!(m)
    end
    _update_constraint_names!(m)
end

function _set_objective!(m::Model; alternative_objective=m -> nothing)
    alt_obj = alternative_objective(m)
    if alt_obj == nothing
        _create_objective_terms!(m)
        total_discounted_costs = sum(
            in_window + beyond_window for (in_window, beyond_window) in values(m.ext[:spineopt].objective_terms)
        )
        if !iszero(total_discounted_costs)
            @objective(m, Min, total_discounted_costs)
        else
            @warn "no objective terms defined"
        end
    else
        alt_obj
    end
end

function _create_objective_terms!(m)
    window_end = end_(current_window(m))
    window_very_end = end_(last(time_slice(m)))
    beyond_window = collect(to_time_slice(m; t=TimeSlice(window_end, window_very_end)))
    in_window = collect(to_time_slice(m; t=current_window(m)))
    filter!(t -> !(t in beyond_window), in_window)
    for term in objective_terms(m)
        func = eval(term)
        m.ext[:spineopt].objective_terms[term] = (func(m, in_window), func(m, beyond_window))
    end
end

function _init_outputs!(m::Model)
    for out in keys(m.ext[:spineopt].reports_by_output)
        get!(m.ext[:spineopt].outputs, out.name, Dict{NamedTuple,Dict}())
    end
end

function run_spineopt_kernel!(
    m,
    url_out;
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    resume_file_path=nothing,

)
    k = _resume_run!(m, resume_file_path, update_constraints, log_level, update_names)
    k === nothing && return m
    calculate_duals = any(
        startswith(lowercase(name), r"bound_|constraint_") for name in String.(keys(m.ext[:spineopt].outputs))
    )
    while optimize
        @log log_level 1 "\nWindow $k: $(current_window(m))"
        optimize_model!(m; log_level=log_level, calculate_duals=calculate_duals) || break
        if write_as_roll > 0 && k % write_as_roll == 0
            _write_intermediate_results(m)                
            _dump_resume_data(m, k, resume_file_path)
            _clear_results!(m)
        end
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
        k += 1
    end
    if write_as_roll > 0
        _write_intermediate_results(m)
    else
        write_report(m, url_out; alternative=alternative, log_level=log_level)
    end
    m
end

_resume_run!(m, ::Nothing, update_constraints, log_level, update_names) = 1
function _resume_run!(m, resume_file_path, update_constraints, log_level, update_names)
    !isfile(resume_file_path) && return 1
    try
        resume_data = JSON.parsefile(resume_file_path)
        k, values = resume_data["window"], resume_data["values"]
        @log log_level 1 "Using data from $resume_file_path to skip through windows 1 to $k..."
        roll_temporal_structure!(m::Model, k - 1)
        _load_variable_values!(m, values)
        if !roll_temporal_structure!(m::Model)
            @log log_level 1 "Nothing to resume - window $k was the last one"
            nothing
        else
            update_model!(m; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
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
function optimize_model!(m::Model; log_level=3, calculate_duals=false, iterations=nothing)
    write_mps_file(model=m.ext[:spineopt].instance) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section.
    @timelog log_level 0 "Optimizing model $(m.ext[:spineopt].instance)..." optimize!(m)
    if termination_status(m) in (MOI.OPTIMAL, MOI.TIME_LIMIT)
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving $(m.ext[:spineopt].instance) results..." _save_model_results!(
            m; iterations=iterations
        )
        calculate_duals && _calculate_duals(m; log_level=log_level)
        @timelog log_level 2 "Saving outputs..." _save_outputs!(m; iterations=iterations)
        true
    elseif termination_status(m) == MOI.INFEASIBLE
        msg = "model is infeasible - if conflicting constraints can be identified, they will be reported below\n"
        printstyled(
            "model is infeasible - if conflicting constraints can be identified, they will be reported below\n";
            bold=true
        )
        try
            _compute_and_print_conflict!(m)
        catch err
            @error err.msg
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
function _save_model_results!(m; iterations=nothing)
    _save_variable_values!(m)
    _save_objective_values!(m)
    postprocess_results!(m)
end

"""
Save the value of all variables in a model.
"""
function _save_variable_values!(m::Model)
    for (name, var) in m.ext[:spineopt].variables
        m.ext[:spineopt].values[name] = Dict(ind => _variable_value(v) for (ind, v) in var)
    end
end

"""
The value of a JuMP variable, rounded if necessary.
"""
_variable_value(v::VariableRef) = (is_integer(v) || is_binary(v)) ? round(Int, JuMP.value(v)) : JuMP.value(v)

"""
Save the value of the objective terms in a model.
"""
function _save_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    for (term, (in_window, _beyond_window)) in m.ext[:spineopt].objective_terms
        m.ext[:spineopt].values[term] = Dict(ind => _value(realize(in_window)))
    end
    m.ext[:spineopt].values[:total_costs] = Dict(
        ind => sum(m.ext[:spineopt].values[term][ind] for term in keys(m.ext[:spineopt].objective_terms); init=0)
    )
    nothing
end

_value(v::GenericAffExpr) = JuMP.value(v)
_value(v) = v

function _calculate_duals(m; log_level=3)
    if has_duals(m)
        _save_marginal_values!(m)
        _save_bound_marginal_values!(m)
    else
        @log log_level 1 "Obtaining duals for $(m.ext[:spineopt].instance)..."
        _calculate_duals_cplex(m; log_level=log_level) && return
        _calculate_duals_fallback(m; log_level=log_level)
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
    @timelog log_level 1 "Optimizing LP..." CPLEX.CPXlpopt(cplex_model.env, cplex_model.lp)
    _save_marginal_values!(m)
    _save_bound_marginal_values!(m)
    CPLEX.CPXchgprobtype(cplex_model.env, cplex_model.lp, prob_type)
    true
end

function _calculate_duals_fallback(m; log_level=3)
    @timelog log_level 1 "Copying model" (m_dual_lp, ref_map) = copy_model(m)
    lp_solver = m.ext[:spineopt].lp_solver
    @timelog log_level 1 "Setting LP solver $(lp_solver)..." set_optimizer(m_dual_lp, lp_solver)
    @timelog log_level 1 "Fixing integer variables..." _fix_integer_vars(m, ref_map)
    _save_marginal_values!(m, ref_map)
    _save_bound_marginal_values!(m, ref_map)
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

function _fix_integer_vars(m::Model, ref_map::ReferenceMap)
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

function _save_marginal_values!(m::Model, ref_map=nothing)
    for (constraint_name, con) in m.ext[:spineopt].constraints
        output_name = Symbol(string("constraint_", constraint_name))
        haskey(m.ext[:spineopt].outputs, output_name) || continue
        m.ext[:spineopt].values[output_name] = Dict(ind => _dual(con[ind], ref_map) for ind in keys(con))
    end
end

function _save_bound_marginal_values!(m::Model, ref_map=nothing)
    for (variable_name, var) in m.ext[:spineopt].variables
        output_name = Symbol(string("bound_", variable_name))
        haskey(m.ext[:spineopt].outputs, output_name) || continue
        m.ext[:spineopt].values[output_name] = Dict(ind => _reduced_cost(var[ind], ref_map) for ind in keys(var))
    end
end

_dual(con, ref_map::JuMP.ReferenceMap) = DualPromise(ref_map[con])
_dual(con, ::Nothing) = has_duals(owner_model(con)) ? dual(con) : nothing

_reduced_cost(var, ref_map::JuMP.ReferenceMap) = ReducedCostPromise(ref_map[var])
_reduced_cost(var, ::Nothing) = has_duals(owner_model(var)) ? reduced_cost(var) : nothing

"""
Save the outputs of a model.
"""
function _save_outputs!(m; iterations=nothing)
    is_last_window = end_(current_window(m)) >= model_end(model=m.ext[:spineopt].instance)
    for (out, rpts) in m.ext[:spineopt].reports_by_output
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

function _value_by_entity_non_aggregated(m, value::Dict, crop_to_window)
    by_entity_non_aggr = Dict()
    analysis_time = start(current_window(m))
    for (ind, val) in value
        t_keys = collect(_time_slice_keys(ind))
        t = maximum(ind[k] for k in t_keys)
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

function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, output_time_slices::Array)
    by_time_stamp_aggr = Dict()
    for t_aggr in output_time_slices
        time_slices = filter(t -> iscontained(t, t_aggr), keys(by_time_slice_non_aggr))
        isempty(time_slices) && continue  # No aggregation possible
        by_time_stamp_aggr[start(t_aggr)] = sum(by_time_slice_non_aggr[t] for t in time_slices) / length(time_slices)
    end
    by_time_stamp_aggr
end
function _value_by_time_stamp_aggregated(by_time_slice_non_aggr, ::Nothing)
    Dict(start(t) => v for (t, v) in by_time_slice_non_aggr)
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
    values = collect_output_values(m)
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

Write report from given model into a db.

# Arguments
- `m::Model`: a JuMP model resulting from running SpineOpt successfully.
- `default_url::String`: a db url to write the report to.
- `output_value`: a function to replace `SpineOpt.output_value` if needed.

# Keyword arguments
- `alternative::String`: an alternative to pass to `SpineInterface.write_parameters`.
"""
function write_report(m, default_url, output_value=output_value; alternative="", log_level=3)
    default_url === nothing && return
    values = collect_output_values(m, output_value)
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

"""
    collect_output_values(m, output_value=output_value)

A Dict mapping tuples (output, overwrite results on rolling) to another Dict mapping entities to TimeSeries or Map
parameter values.

# Arguments
- `m::Model`: a JuMP model resulting from running SpineOpt successfully.
- `output_value`: a function to replace `SpineOpt.output_value` if needed.
"""
function collect_output_values(m, output_value=output_value)
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

A value from a SpineOpt result.

# Arguments
- `by_analysis_time::Dict`: mapping analysis times, to timestamps, to values.
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
    TimeSeries(
        [ts for by_time_stamp in values(by_analysis_time_sorted) for ts in keys(by_time_stamp)],
        [val for by_time_stamp in values(by_analysis_time_sorted) for val in values(by_time_stamp)],
        false,
        false;
        merge_ok=true
    )
end
function _output_value(by_analysis_time, overwrite_results_on_rolling::Val{false})
    Map(
        collect(keys(by_analysis_time)),
        [
            TimeSeries(collect(keys(by_time_stamp)), collect(values(by_time_stamp)), false, false)
            for by_time_stamp in values(by_analysis_time)
        ]
    )
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
function update_model!(m; update_constraints=m -> nothing, log_level=3, update_names=false)
    if update_names
        _update_variable_names!(m)
        _update_constraint_names!(m)
    end
    @timelog log_level 2 "Fixing history..." _fix_history!(m)
    @timelog log_level 2 "Applying non-anticipativity constraints..." apply_non_anticipativity_constraints!(m)
    @timelog log_level 2 "Updating user constraints..." update_constraints(m)
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
            fix(var[history_ind], val[ind]; force=true)
        end
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
    window_start = start(current_window(m))
    roll_forward_ = roll_forward(model=m.ext[:spineopt].instance)
    for ent in SpineInterface.indices_as_tuples(non_anticipativity_time)
        for ind in indices(m; t=time_slice(m), ent...)
            non_ant_time = non_anticipativity_time(; ind..., _strict=false)
            non_ant_margin = if non_anticipativity_margin === nothing
                nothing
            else
                non_anticipativity_margin(; ind..., _strict=false)
            end
            if non_ant_time != nothing && start(ind.t) < window_start +  non_ant_time
                next_t = to_time_slice(m; t=ind.t + roll_forward_)
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
