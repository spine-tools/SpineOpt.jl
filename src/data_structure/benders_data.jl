#############################################################################
# Copyright (C) 2017 - 2021  Spine Project
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
        if t_end !== nothing
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
        with_env(st.name) do
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

function _save_sp_solution!(m, k)
    m.ext[:spineopt].sp_values[k] = Dict(
        name => copy(m.ext[:spineopt].values[name])
        for name in keys(m.ext[:spineopt].variables)
        if !occursin("invested", string(name))
    )
end

function _set_sp_solution!(m, k; _kwargs...)
    for (name, vals) in get(m.ext[:spineopt].sp_values, k, ())
        var = m.ext[:spineopt].variables[name]
        for (ind, val) in vals
            var[ind] isa VariableRef && set_start_value(var[ind], val)
        end
    end
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
