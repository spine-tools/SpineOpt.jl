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

"""
    run_spineopt(url_in, url_out; <keyword arguments>)

Run the SpineOpt from `url_in` and write report to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Keyword arguments

**`with_optimizer=with_optimizer(Cbc.Optimizer, logLevel=0)`** is the optimizer factory for building the JuMP model.

**`cleanup=true`** tells [`run_spineopt`](@ref) whether or not convenience functors should be
set to `nothing` after completion.

**`add_constraints=m -> nothing`** is called with the `Model` object in the first optimization window,
    and allows adding user contraints.

**`update_constraints=m -> nothing`** is called in windows 2 to the last, and allows updating contraints
    added by `add_constraints`.

**`log_level=3`** is the log level.
"""
function run_spineopt(
    url_in::String,
    url_out::String=url_in;
    upgrade=false,
    mip_solver=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
    lp_solver=optimizer_with_attributes(Clp.Optimizer, "LogLevel" => 0),
    cleanup=true,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false,
)
    @log log_level 0 "Running SpineOpt for $(url_in)..."
    @timelog log_level 2 "Initializing data structure from db..." begin
        using_spinedb(url_in, @__MODULE__; upgrade=upgrade)
        generate_missing_items()
    end

    # High-level algorithm selection. For now, selecting based on defined model types,
    # but may want more robust system in future

    if !isempty(model(model_type=:spineopt_master))
        rerun_spineopt_mp(
            url_out;
            mip_solver=mip_solver,
            lp_solver=lp_solver,
            add_constraints=add_constraints,
            update_constraints=update_constraints,
            log_level=log_level,
            optimize=optimize,
            use_direct_model=use_direct_model,
        )
    else
        rerun_spineopt(
            url_out;
            mip_solver=mip_solver,
            lp_solver=lp_solver,
            add_constraints=add_constraints,
            update_constraints=update_constraints,
            log_level=log_level,
            optimize=optimize,
            use_direct_model=use_direct_model,
        )
    end
end

function rerun_spineopt(
    url_out::String;
    mip_solver=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
    lp_solver=optimizer_with_attributes(Clp.Optimizer, "LogLevel" => 0),
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false,
)
    outputs = Dict()

    m = create_model(mip_solver, use_direct_model, :spineopt_operations)

    @timelog log_level 2 "Preprocessing operations model specific data structure...\n" preprocess_model_data_structure(
        m,
    )
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure(m)
    @log log_level 1 "Window 1: $(current_window(m))"
    init_model!(m; add_constraints=add_constraints, log_level=log_level)
    calculate_duals = duals_calculation_needed(m)
    k = 2


    while optimize && optimize_model!(
        m;
        log_level=log_level,
        mip_solver=mip_solver,
        lp_solver=lp_solver,
        calculate_duals=calculate_duals,
    )
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving results..." save_model_results!(outputs, m)
        @timelog log_level 2 "Rolling temporal structure...\n" roll_temporal_structure!(m) || break
        @log log_level 1 "Window $k: $(current_window(m))"
        update_model!(m; update_constraints=update_constraints, log_level=log_level)
        k += 1
    end
    @timelog log_level 2 "Writing report..." write_report(m, url_out)
    m
end


"""
A JuMP `Model` for SpineOpt.
"""
function create_model(mip_solver, use_direct_model=false, model_type=:spineopt_operations)

    m = use_direct_model ? direct_model(mip_solver) : Model(mip_solver)
    length(model(model_type=model_type)) == 0 && error("No model of type $model_type defined")
    m.ext[:instance] = first(model(model_type=model_type))
    m.ext[:variables] = Dict{Symbol,Dict}()
    m.ext[:variables_definition] = Dict{Symbol,Dict}()
    m.ext[:values] = Dict{Symbol,Dict}()
    m.ext[:constraints] = Dict{Symbol,Dict}()
    m.ext[:marginals] = Dict{Symbol,Dict}()
    m.ext[:outputs] = Dict()
    m.ext[:integer_variables] = []
    m.ext[:is_subproblem] = false
    m.ext[:objective_lower_bound] = 0.0
    m.ext[:objective_upper_bound] = 0.0
    m.ext[:benders_gap] = 0.0
    m

end


"""
Add SpineOpt variables to the given model.
"""
function add_variables!(m; log_level=3)
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
        fix_value_ = fix_value(ind)
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


"""
Add SpineOpt constraints to the given model.
"""
function add_constraints!(m; add_constraints=m -> nothing, log_level=3)    
    @timelog log_level 3 "- [constraint_unit_pw_heat_rate]" add_constraint_unit_pw_heat_rate!(m)    
    @timelog log_level 3 "- [constraint_unit_constraint]" add_constraint_unit_constraint!(m)
    @timelog log_level 3 "- [constraint_node_injection]" add_constraint_node_injection!(m)
    @timelog log_level 3 "- [constraint_nodal_balance]" add_constraint_nodal_balance!(m)
    @timelog log_level 3 "- [constraint_candidate_connection_flow_ub]" add_constraint_candidate_connection_flow_ub!(m)
    @timelog log_level 3 "- [constraint_candidate_connection_flow_lb]" add_constraint_candidate_connection_flow_lb!(m)
    @timelog log_level 3 "- [constraint_connection_intact_flow_ptdf]" add_constraint_connection_intact_flow_ptdf!(m)
    #@timelog log_level 3 "- [constraint_connection_intact_flow_ptdf_in_out]" add_constraint_connection_intact_flow_ptdf_in_out!(m)
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
    @timelog log_level 3 "- [constraint_fix_ratio_out_in_connection_flow]" add_constraint_fix_ratio_out_in_connection_flow!(
        m,
    )
    @timelog log_level 3 "- [constraint_max_ratio_out_in_connection_flow]" add_constraint_max_ratio_out_in_connection_flow!(
        m,
    )
    @timelog log_level 3 "- [constraint_min_ratio_out_in_connection_flow]" add_constraint_min_ratio_out_in_connection_flow!(
        m,
    )           
    @timelog log_level 3 "- [constraint_node_state_capacity]" add_constraint_node_state_capacity!(m)
    @timelog log_level 3 "- [constraint_max_cum_in_unit_flow_bound]" add_constraint_max_cum_in_unit_flow_bound!(m)
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
    @timelog log_level 3 "- [constraint_user]" add_constraints(m)

    # Name constraints
    for (con_key, cons) in m.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key, inds))
        end
    end
end

function duals_calculation_needed(m::Model)
    calculate_duals = false
    for r in model__report(model=m.ext[:instance])
        for o in report__output(report=r)
            get!(m.ext[:outputs], o.name, Dict{NamedTuple,Dict}())
            output_name = lowercase(String(o.name))
            startswith(output_name, r"bound_|constraint_") && (calculate_duals = true)
        end
    end
    calculate_duals
end

"""
Initialize the given model for SpineOpt: add variables, fix the necessary variables, add constraints and set objective.
"""
function init_model!(m; add_constraints=m -> nothing, log_level=3)
    @timelog log_level 2 "Adding variables...\n" add_variables!(m; log_level=log_level)
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Adding constraints...\n" add_constraints!(
        m;
        add_constraints=add_constraints,
        log_level=log_level,
    )
    @timelog log_level 2 "Setting objective..." set_objective!(m)
end

"""
Optimize the given model. If an optimal solution is found, return `true`, otherwise return `false`.
"""
function optimize_model!(m::Model; log_level=3, calculate_duals=false, mip_solver, lp_solver)
    write_mps_file(model=m.ext[:instance]) == :write_mps_always && write_to_file(m, "model_diagnostics.mps")
    # NOTE: The above results in a lot of Warning: Variable connection_flow[...] is mentioned in BOUNDS,
    # but is not mentioned in the COLUMNS section. We are ignoring it.
    @timelog log_level 0 "Optimizing model $(m.ext[:instance])..." optimize!(m)
    if termination_status(m) == MOI.OPTIMAL || termination_status(m) == MOI.TIME_LIMIT
        if calculate_duals
            @timelog log_level 0 "Fixing integer values for final LP to obtain duals..." relax_integer_vars(m)
            if lp_solver != mip_solver
                @timelog log_level 0 "Switching to LP solver $(lp_solver)..." set_optimizer(m, lp_solver)
            end
            @timelog log_level 0 "Optimizing final LP of $(m.ext[:instance]) to obtain duals..." optimize!(m)
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
        for
        ind in indices(m; t=vcat(history_time_slice(m), time_slice(m))) if end_(ind.t) <= end_(current_window(m))
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

"""
Drop keys from a `NamedTuple`.
"""
_drop_key(x::NamedTuple, key::Symbol...) = (; (k => v for (k, v) in pairs(x) if !(k in key))...)

"""
Save the outputs of a model into a dictionary.
"""
function save_outputs!(m)
    for r in model__report(model=m.ext[:instance]), o in report__output(report=r)
        name = o.name
        value = get(m.ext[:values], name, nothing)
        if value === nothing
            @warn "can't find a value for '$(name)'"
            continue
        end
        existing = get!(m.ext[:outputs], name, Dict{NamedTuple,Dict}())
        for (k, v) in value
            end_(k.t) <= model_start(model=m.ext[:instance]) && continue
            new_k = _drop_key(k, :t)
            push!(get!(existing, new_k, Dict{DateTime,Any}()), start(k.t) => v)
        end
    end
end

"""
Save a model results: first postprocess results, then save variables and objective values, and finally save outputs
"""
function save_model_results!(outputs, m)
    postprocess_results!(m)
    save_variable_values!(m)
    save_objective_values!(m)
    save_marginal_values!(m)
    save_bound_marginal_values!(m)
    save_outputs!(m)
end

"""
Update the given model for the next window in the rolling horizon: update variables, fix the necessary variables,
update constraints and update objective.
"""
function update_model!(m; update_constraints=m -> nothing, log_level=3)
    # The below is needed here because we remove the integer constraints to get a dual solution
    # and then need to re-add them for the next write_mps_on_no_solve
    # we can only do this once we have saved the solution
    @timelog log_level 2 "Setting integers and binaries..." unrelax_integer_vars(m)
    @timelog log_level 2 "Updating variables..." update_variables!(m)
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Updating constraints..." update_varying_constraints!(m)
    @timelog log_level 2 "Updating user constraints..." update_constraints(m)
    @timelog log_level 2 "Updating objective..." update_varying_objective!(m)
end

"""
Write report from given outputs into the db.
"""
function write_report(model, default_url)
    reports = Dict()
    outputs = Dict()

    for rpt in model__report(model=model.ext[:instance])
        for out in report__output(report=rpt)
            d = get!(model.ext[:outputs], out.name, nothing)
            d === nothing && continue
            output_url = output_db_url(report=rpt, _strict=false)
            url = output_url !== nothing ? output_url : default_url
            url_reports = get!(reports, url, Dict())
            output_params = get!(url_reports, rpt.name, Dict{Symbol,Dict{NamedTuple,TimeSeries}}())
            parameter_name = out.name in objective_terms(model) ? Symbol("objective_", out.name) : out.name
            output_params[parameter_name] =
                Dict(k => TimeSeries(collect(keys(v)), collect(values(v)), false, false) for (k, v) in d)
        end
    end
    for (url, url_reports) in reports
        for (rpt_name, output_params) in url_reports
            write_parameters(output_params, url; report=string(rpt_name))
        end
    end
end


function relax_integer_vars(m::Model)
    save_integer_values!(m)    
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]
        bin = def[:bin]
        int = def[:int]
        var = m.ext[:variables][name]
        for ind in def[:indices](m; t=vcat(history_time_slice(m), time_slice(m)))
            
            if end_(ind.t) <= end_(current_window(m))
                fix(var[ind], m.ext[:values][name][ind]; force=true)
            end
            
            bin != nothing && bin(ind) && unset_binary(var[ind])
            int != nothing && int(ind) && unset_integer(var[ind])
        end
    end
end


function unrelax_integer_vars(m::Model)
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]
        bin = def[:bin]
        int = def[:int]
        indices = def[:indices]
        var = m.ext[:variables][name]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
            if end_(ind.t) <= end_(current_window(m))
                bin != nothing && bin(ind) && set_binary(var[ind])
                int != nothing && int(ind) && set_integer(var[ind])
            end
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
    m.ext[:values][output_name] =
        Dict(ind => JuMP.dual(con[ind]) for ind in inds if end_(ind.t) <= end_(current_window(m)))
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
        for
        ind in indices(m; t=vcat(history_time_slice(m), time_slice(m))) if end_(ind.t) <= end_(current_window(m))
    )
end
