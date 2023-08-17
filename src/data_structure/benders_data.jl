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
function _pval_by_entity(vals, weight=1.0)
    by_ent = Dict()
    for (ind, val) in vals
        ent = _drop_key(ind, :stochastic_scenario, :t)
        by_s = get!(by_ent, ent, Dict())
        by_t = get!(by_s, ind.stochastic_scenario, Dict())
        by_t[ind.t] = realize(val)
    end
    Dict(
        ent => parameter_value(Map(collect(keys(by_s)), [_window_time_series(by_t, weight) for by_t in values(by_s)]))
        for (ent, by_s) in by_ent
    )
end

"""
    _window_time_series(by_t, weight)

A `TimeSeries` from the given `Dict` mapping `TimeSlice` to `Float64`, with an explicit NaN at the end.
The NaN is there because we want to merge marginal values from different windows of the Benders subproblem
into one `TimeSeries`.

Without the NaN, the last value of one window would apply until the next window, which wouldn't be correct
if there were gaps between the windows (as in rolling representative periods Benders).
With the NaN, the gap is correctly skipped in the Benders cuts.
"""
function _window_time_series(by_t, weight)
    time_slices, vals = collect(keys(by_t)), collect(values(by_t))
    inds = start.(time_slices)
    push!(inds, maximum(end_.(time_slices)))
    push!(vals, NaN)
    TimeSeries(inds, weight * vals)
end

function process_master_problem_solution!(m_mp)
    _save_mp_values!(m_mp, :units_invested_available, unit)
    _save_mp_values!(m_mp, :connections_invested_available, connection)
    _save_mp_values!(m_mp, :storages_invested_available, node)
end

function _save_mp_values!(m_mp, var_name, obj_cls)
    benders_param_name = Symbol(:internal_fix_, var_name)
    pval_by_ent = _pval_by_entity(m_mp.ext[:spineopt].values[var_name])
    pvals = Dict(only(ent) => Dict(benders_param_name => pval) for (ent, pval) in pval_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function process_subproblem_solution!(m, win_weight)
    _save_sp_marginal_values!(m, win_weight)
    _save_sp_objective_value!(m, win_weight)
    _save_sp_unit_flow!(m, win_weight)
    _save_sp_solution!(m)
end

function save_sp_objective_value_tail!(m, win_weight)
    _save_sp_objective_value!(m, win_weight, true)
end

function _save_sp_marginal_values!(m, win_weight)
    _wait_for_dual_solves(m)
    _save_sp_marginal_values!(m, :bound_units_invested_available, :units_invested_available_mv, unit, win_weight)
    _save_sp_marginal_values!(
        m, :bound_connections_invested_available, :connections_invested_available_mv, connection, win_weight
    )
    _save_sp_marginal_values!(m, :bound_storages_invested_available, :storages_invested_available_mv, node, win_weight)
end

function _save_sp_marginal_values!(m, var_name, param_name, obj_cls, win_weight)
    win_start, win_end = start(current_window(m)), end_(current_window(m))
    window_values = Dict(
        k => v for (k, v) in m.ext[:spineopt].values[var_name] if start(k.t) >= win_start && end_(k.t) <= win_end
    )
    pval_by_ent = _pval_by_entity(window_values, win_weight)
    pvals = Dict(only(ent) => Dict(param_name => pval) for (ent, pval) in pval_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function _save_sp_objective_value!(m, win_weight, tail=false)
    key = tail ? :total_costs_tail : :total_costs
    increment = sum(values(m.ext[:spineopt].values[key]); init=0)
    total_sp_obj_val = sp_objective_value_bi(benders_iteration=current_bi, _default=0) + win_weight * increment
    add_object_parameter_values!(
        benders_iteration, Dict(current_bi => Dict(:sp_objective_value_bi => parameter_value(total_sp_obj_val)))
    )
end

function _save_sp_unit_flow!(m, win_weight, tail=false)
    win_start, win_end = start(current_window(m)), end_(current_window(m))
    window_values = Dict(
        k => v for (k, v) in m.ext[:spineopt].values[:unit_flow] if start(k.t) >= win_start && end_(k.t) <= win_end
    )
    pval_by_ent = _pval_by_entity(window_values, win_weight)
    pvals_to_node = Dict(
        ent => Dict(:sp_unit_flow => pval) for (ent, pval) in pval_by_ent if ent.direction == direction(:to_node)
    )
    pvals_from_node = Dict(
        ent => Dict(:sp_unit_flow => pval) for (ent, pval) in pval_by_ent if ent.direction == direction(:from_node)
    )
    add_relationship_parameter_values!(unit__to_node, pvals_to_node; merge_values=true)
    add_relationship_parameter_values!(unit__from_node, pvals_from_node; merge_values=true)
end


function _save_sp_solution!(m)    
    m.ext[:spineopt].sp_values[m.ext[:spineopt].temporal_structure[:current_window_number]] = copy(m.ext[:spineopt].values)    
end


function _set_sp_solution!(m)
    for (name, var) in m.ext[:spineopt].variables    
        for (ind, v) in var
            set_start_value(v, m.ext[:spineopt].sp_values[m.ext[:spineopt].temporal_structure[:current_window_number]][name][ind]) 
        end
    end
end


function save_mp_objective_bounds_and_gap!(m_mp)
    obj_lb = m_mp.ext[:spineopt].objective_lower_bound[] = objective_value(m_mp)
    sp_obj_val = sp_objective_value_bi(benders_iteration=current_bi, _default=0)
    invest_costs = value(realize(total_costs(m_mp, anything; operations=false)))
    obj_ub = m_mp.ext[:spineopt].objective_upper_bound[] = sp_obj_val + invest_costs
    gap = 2 * (obj_ub - obj_lb) / (obj_ub + obj_lb)
    push!(m_mp.ext[:spineopt].benders_gaps, gap)
end

function add_benders_iteration(j)
    new_bi = Object(Symbol(:bi_, j))
    add_object!(benders_iteration, new_bi)
    new_bi
end
