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
        ent => parameter_value(
            Map(
                collect(keys(by_s)),
                [TimeSeries(start.(keys(by_t)), weight * collect(values(by_t))) for by_t in values(by_s)]
            )
        )
        for (ent, by_s) in by_ent
    )
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
end

function save_sp_objective_value_tail!(m, win_weight)
    _save_sp_objective_value!(m, win_weight, true)
end

function _save_sp_marginal_values!(m, win_weight)
    _wait_for_dual_solves(m)
    _save_sp_marginal_values!(m, :bound_units_on, :units_on_mv, unit, win_weight)
    _save_sp_marginal_values!(
        m, :bound_connections_invested_available, :connections_invested_available_mv, connection, win_weight
    )
    _save_sp_marginal_values!(m, :bound_storages_invested_available, :storages_invested_available_mv, node, win_weight)
end

function _save_sp_marginal_values!(m, var_name, benders_param_name, obj_cls, win_weight)
    win_start = start(current_window(m))
    window_values = Dict(k => v for (k, v) in m.ext[:spineopt].values[var_name] if start(k.t) >= win_start)
    pval_by_ent = _pval_by_entity(window_values, win_weight)
    pvals = Dict(only(ent) => Dict(benders_param_name => pval) for (ent, pval) in pval_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function _save_sp_objective_value!(m, win_weight, tail=false)
    in_window_obj_val = sum(values(m.ext[:spineopt].values[:total_costs]), init=0)
    increment = tail ? value(realize(total_costs(m, anything))) - in_window_obj_val : in_window_obj_val
    total_sp_obj_val = sp_objective_value_bi(benders_iteration=current_bi, _default=0) + win_weight * increment
    add_object_parameter_values!(
        benders_iteration, Dict(current_bi => Dict(:sp_objective_value_bi => parameter_value(total_sp_obj_val)))
    )
end

function save_mp_objective_bounds_and_gap!(m_mp)
    obj_lb = m_mp.ext[:spineopt].objective_lower_bound[] = sum(
        values(m_mp.ext[:spineopt].values[:mp_objective_lowerbound]); init=0
    )
    obj_ub = m_mp.ext[:spineopt].objective_upper_bound[] = sp_objective_value_bi(
        benders_iteration=current_bi, _default=0
    )
    gap = 2 * (obj_ub - obj_lb) / (obj_ub + obj_lb)
    push!(m_mp.ext[:spineopt].benders_gaps, gap)
end

function add_benders_iteration(j)
    new_bi = Object(Symbol(:bi_, j))
    add_object!(benders_iteration, new_bi)
    new_bi
end
