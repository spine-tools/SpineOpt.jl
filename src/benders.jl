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
"""
Initialize the given model for SpineOpt Master Problem: add variables, add constraints and set objective.
"""
function _build_mp_model!(m; log_level=3)
    num_variables(m) == 0 || return
    model_name = _model_name(m)
    @timelog log_level 2 "Creating $model_name temporal structure..." generate_master_temporal_structure!(m)
    @timelog log_level 2 "Creating $model_name stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Adding $model_name variables...\n" _add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding $model_name constraints...\n" _add_mp_constraints!(m; log_level=log_level)
    @timelog log_level 2 "Setting $model_name objective..." _set_mp_objective!(m)
    _init_outputs!(m)
    _call_event_handlers(m, :model_built)
end

"""
Add SpineOpt Master Problem variables to the given model.
"""
function _add_mp_variables!(m; log_level=3)
    for add_variable! in (
            add_variable_sp_objective_upperbound!,
            add_variable_units_invested!,
            add_variable_units_invested_available!,
            add_variable_units_mothballed!,
            add_variable_connections_invested!,
            add_variable_connections_invested_available!,
            add_variable_connections_decommissioned!,
            add_variable_storages_invested!,
            add_variable_storages_invested_available!,
            add_variable_storages_decommissioned!,
            add_variable_mp_min_res_gen_to_demand_ratio_slack!,
        )
        name = name_from_fn(add_variable!)
        @timelog log_level 3 "- [$name]" add_variable!(m)
    end
    _expand_replacement_expressions!(m)
end

"""
Add SpineOpt master problem constraints to the given model.
"""
function _add_mp_constraints!(m; log_level=3)
    for add_constraint! in (
            _add_constraint_sp_objective_upperbound!,
            add_constraint_unit_lifetime!,
            add_constraint_units_invested_transition!,
            add_constraint_units_invested_available!,
            add_constraint_connection_lifetime!,
            add_constraint_connections_invested_transition!,
            add_constraint_connections_invested_available!,
            add_constraint_storage_lifetime!,
            add_constraint_storages_invested_transition!,
            add_constraint_storages_invested_available!,
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

function _add_constraint_sp_objective_upperbound!(m::Model)
    @fetch sp_objective_upperbound = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:mp_objective] = Dict(
        (t=t,) => @constraint(m, sp_objective_upperbound[t] >= 0) for (t,) in sp_objective_upperbound_indices(m)
    )
end

"""
    _set_mp_objective!(m::Model)

Minimize total investment costs plus upperbound on subproblem objective.
"""
function _set_mp_objective!(m::Model)
    @fetch sp_objective_upperbound = m.ext[:spineopt].variables
    _create_mp_objective_terms!(m)
    @objective(
        m,
        Min,
        + sum(sp_objective_upperbound[t] for (t,) in sp_objective_upperbound_indices(m); init=0)
        + investment_costs(m)
    )
end

function _create_mp_objective_terms!(m)
    for term in objective_terms(m; benders_subproblem=false)
        func = getproperty(SpineOpt, term)
        m.ext[:spineopt].objective_terms[term] = (func(m, anything), 0)
    end
end

"""
Add benders cuts to master problem.
"""
function _add_mp_cuts!(m; log_level=3)
    for add_constraint! in (
            add_constraint_mp_any_invested_cuts!,
            add_constraint_mp_min_res_gen_to_demand_ratio_cuts!,
        )
        name = name_from_fn(add_constraint!)
        @timelog log_level 3 "- [$name]" add_constraint!(m)
    end
    _update_constraint_names!(m)
end

"""
Force starting investments and return a function to be called without arguments to undo the operation.
"""
function _force_starting_investments!(m::Model)
    callbacks = vcat(
        _do_force_starting_investments!(m, :units_invested_available, benders_starting_units_invested),
        _do_force_starting_investments!(m, :connections_invested_available, benders_starting_connections_invested),
        _do_force_starting_investments!(m, :storages_invested_available, benders_starting_storages_invested),
    )
    () -> for c in callbacks c() end
end

function _do_force_starting_investments!(m::Model, variable_name::Symbol, benders_starting_invested::Parameter)
    callbacks = []
    for (ind, var) in m.ext[:spineopt].variables[variable_name]
        start(ind.t) >= start(current_window(m)) || continue
        starting_invested = benders_starting_invested(; ind..., _strict=false)
        starting_invested === nothing && continue
        push!(callbacks, () -> unfix(var))
        if has_lower_bound(var)
            x = lower_bound(var)
            push!(callbacks, () -> set_lower_bound(var, x))
        end
        if has_upper_bound(var)
            x = upper_bound(var)
            push!(callbacks, () -> set_upper_bound(var, x))
        end
        if is_fixed(var)
            x = fix_value(var)
            push!(callbacks, () -> fix(var, x; force=true))
        end
        fix(var, starting_invested; force=true)
    end
    callbacks
end

"""
    _pval_by_entity(vals)

Take the given Dict, which should be a mapping from variable indices to their value,
and return another Dict mapping entities to `ParameterValue`s.

The keys in the result are the keys of the input, without the stochastic_scenario and the t (i.e., just the entity).
The values are `ParameterValue{Map}`s mapping the `stochastic_scenario` of the variable key,
to a `TimeSeries` mapping the `t` of the key, to the 'realized' variable value.
"""
function _pval_by_entity(vals, t_end=nothing)
    by_ent = Dict()
    for (ind, val) in vals
        ent = _drop_key(ind, :stochastic_scenario, :t)
        by_s = get!(by_ent, ent, Dict())
        by_t = get!(by_s, ind.stochastic_scenario, Dict())
        realized_val = realize(val)
        if t_end !== nothing && t_end < end_(ind.t)
            realized_val *= (t_end - start(ind.t)) / (end_(ind.t) - start(ind.t))
        end
        by_t[ind.t] = realized_val
    end
    Dict(
        ent => parameter_value(Map(collect(keys(by_s)), [_window_time_series(by_t) for by_t in values(by_s)]))
        for (ent, by_s) in by_ent
    )
end

"""
    _window_time_series(by_t)

A `TimeSeries` from the given `Dict` mapping `TimeSlice` to `Float64`, with an explicit NaN at the end.
The NaN is there because we want to merge marginal values from different windows of the Benders subproblem
into one `TimeSeries`.

Without the NaN, the last value of one window would apply until the next window, which wouldn't be correct
if there were gaps between the windows (as in rolling representative periods Benders).
With the NaN, the gap is correctly skipped in the Benders cuts.
"""
function _window_time_series(by_t)
    time_slices, vals = collect(keys(by_t)), collect(values(by_t))
    inds = start.(time_slices)
    push!(inds, maximum(end_.(time_slices)))
    push!(vals, NaN)
    TimeSeries(inds, vals)
end

function process_master_problem_solution(m_mp, m)
    _save_mp_values!(unit, m_mp, m, :units_invested_available)
    _save_mp_values!(connection, m_mp, m, :connections_invested_available)
    _save_mp_values!(node, m_mp, m, :storages_invested_available)
end

function _save_mp_values!(obj_cls, m_mp, m, var_name)
    benders_param_name = Symbol(:internal_fix_, var_name)
    pval_by_ent = _pval_by_entity(m_mp.ext[:spineopt].values[var_name])
    pvals = Dict(only(ent) => Dict(benders_param_name => pval) for (ent, pval) in pval_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
    for st in keys(m.ext[:spineopt].model_by_stage)
        with_env(stage_scenario(stage=st)) do
            add_object_parameter_values!(obj_cls, pvals; merge_values=true)
        end
    end
end

function process_subproblem_solution(m, k)
    win_weight = window_weight(model=m.ext[:spineopt].instance, i=k, _strict=false)
    win_weight = win_weight !== nothing ? win_weight : 1.0
    _save_sp_marginal_values(m, k, win_weight)
    _save_sp_objective_value(m, k, win_weight)
    _save_sp_unit_flow(m)
end

function _save_sp_marginal_values(m, k, win_weight)
    _wait_for_dual_solves(m)
    _save_sp_marginal_values!(unit, m, :bound_units_invested_available, :units_invested_available_mv, k, win_weight)
    _save_sp_marginal_values!(
        connection, m, :bound_connections_invested_available, :connections_invested_available_mv, k, win_weight
    )
    _save_sp_marginal_values!(
        node, m, :bound_storages_invested_available, :storages_invested_available_mv, k, win_weight
    )
end

function _is_last_window(m, k)
    k == m.ext[:spineopt].temporal_structure[:window_count]
end

function _save_sp_marginal_values!(obj_cls, m, var_name, param_name, k, win_weight)
    vals = Dict(
        k => win_weight * realize(v)
        for (k, v) in m.ext[:spineopt].values[var_name]
        if start(current_window(m)) <= start(k.t) < end_(current_window(m))
    )
    if _is_last_window(m, k)
        merge!(
            vals,
            Dict(
                k => realize(v) for (k, v) in m.ext[:spineopt].values[var_name] if start(k.t) >= end_(current_window(m))
            )
        )
    end
    pval_by_ent = _pval_by_entity(vals, _is_last_window(m, k) ? nothing : end_(current_window(m)))
    pvals = Dict(only(ent) => Dict(param_name => pval) for (ent, pval) in pval_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function _save_sp_objective_value(m, k, win_weight)
    current_sp_obj_val = win_weight * sum(values(m.ext[:spineopt].values[:total_costs]); init=0)
    if _is_last_window(m, k)
        current_sp_obj_val += sum(values(m.ext[:spineopt].values[:total_costs_tail]); init=0)
    end
    previous_sp_obj_val = k == 1 ? 0 : sp_objective_value_bi(benders_iteration=current_bi, _default=0)
    total_sp_obj_val = previous_sp_obj_val + current_sp_obj_val
    add_object_parameter_values!(
        benders_iteration, Dict(current_bi => Dict(:sp_objective_value_bi => parameter_value(total_sp_obj_val)))
    )
end

function _save_sp_unit_flow(m)
    window_values = Dict(
        k => v for (k, v) in m.ext[:spineopt].values[:unit_flow] if iscontained(k.t, current_window(m))
    )
    pval_by_ent = _pval_by_entity(window_values)
    pvals_to_node = Dict(
        ent => Dict(:sp_unit_flow => pval) for (ent, pval) in pval_by_ent if ent.direction == direction(:to_node)
    )
    pvals_from_node = Dict(
        ent => Dict(:sp_unit_flow => pval) for (ent, pval) in pval_by_ent if ent.direction == direction(:from_node)
    )
    add_relationship_parameter_values!(unit__to_node, pvals_to_node; merge_values=true)
    add_relationship_parameter_values!(unit__from_node, pvals_from_node; merge_values=true)
end

function save_mp_objective_bounds_and_gap!(m_mp)
    obj_lb = m_mp.ext[:spineopt].objective_lower_bound[] = objective_value(m_mp)
    sp_obj_val = sp_objective_value_bi(benders_iteration=current_bi, _default=0)
    obj_ub = m_mp.ext[:spineopt].objective_upper_bound[] = sp_obj_val + value(realize(investment_costs(m_mp)))
    gap = (obj_ub == obj_lb) ? 0 : 2 * (obj_ub - obj_lb) / (obj_ub + obj_lb)
    push!(m_mp.ext[:spineopt].benders_gaps, gap)
end

function investment_costs(m_mp)
    sum(in_window for (in_window, _bw) in values(m_mp.ext[:spineopt].objective_terms))
end

function add_benders_iteration(j)
    new_bi = Object(Symbol(:bi_, j))
    add_object!(benders_iteration, new_bi)
    new_bi
end

