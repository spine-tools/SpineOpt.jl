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
    _map_by_entity(vals)

Take the given Dict, which should be a mapping from variable indices to their value,
and return another Dict mapping entities to `Map`s.

The keys in the result are the keys of the input, without the stochastic_scenario and the t (i.e., just the entity).
The values are `Map`s mapping the `stochastic_scenario` of the variable key,
to a `TimeSeries` mapping the `t` of the key, to the 'realized' variable value.
"""
function _map_by_entity(vals)
    by_ent = Dict()
    for (ind, val) in vals
        ent = _drop_key(ind, :stochastic_scenario, :t)
        by_s = get!(by_ent, ent, Dict())
        by_t = get!(by_s, ind.stochastic_scenario, Dict())
        by_t[ind.t] = val
    end
    Dict(
        ent => Map(
            collect(keys(by_s)), [TimeSeries(start.(keys(by_t)), realize.(values(by_t))) for by_t in values(by_s)]
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
    map_by_ent = _map_by_entity(m_mp.ext[:spineopt].values[var_name])
    pvals = Dict(only(ent) => Dict(benders_param_name => parameter_value(val)) for (ent, val) in map_by_ent)
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function process_subproblem_solution!(m, win_nb)
    win_weight = window_weight(model=m.ext[:spineopt].instance, i=win_nb, _strict=false)
    win_weight = win_weight !== nothing ? win_weight : 1.0
    _save_sp_marginal_values!(m, win_weight)
    _save_sp_objective_value!(m, win_weight)
    _save_sp_unit_flow!(m)
    _save_sp_solution!(m, win_nb)
end

function _save_sp_marginal_values!(m, win_weight)
    _wait_for_dual_solves(m)
    _save_sp_marginal_values!(
        m, :bound_units_invested_available, :units_invested_available_mv, unit, win_weight
    )
    _save_sp_marginal_values!(
        m, :bound_connections_invested_available, :connections_invested_available_mv, connection, win_weight
    )
    _save_sp_marginal_values!(
        m, :bound_storages_invested_available, :storages_invested_available_mv, node, win_weight
    )
end

function _save_sp_marginal_values!(m, var_name, param_name, obj_cls, win_weight)
    map_by_ent = _map_by_entity(m.ext[:spineopt].values[var_name])
    at = start(current_window(m))
    pvals = Dict(
        only(ent) => Dict(param_name => parameter_value(Map([at], [win_weight * val]))) for (ent, val) in map_by_ent
    )
    add_object_parameter_values!(obj_cls, pvals; merge_values=true)
end

function _save_sp_objective_value!(m, win_weight)
    total_costs = sum(sum(values(m.ext[:spineopt].values[k]); init=0) for k in (:total_costs, :total_costs_tail))
    at = start(current_window(m))
    total_sp_obj_val = Map([at], [win_weight * total_costs])
    add_object_parameter_values!(
        benders_iteration,
        Dict(current_bi => Dict(:sp_objective_value_bi => parameter_value(total_sp_obj_val)));
        merge_values=true,
    )
end

function _save_sp_unit_flow!(m)
    window_values = Dict(
        k => v for (k, v) in m.ext[:spineopt].values[:unit_flow] if iscontained(k.t, current_window(m))
    )
    map_by_ent = _map_by_entity(window_values)
    pvals_to_node = Dict(
        ent => Dict(:sp_unit_flow => parameter_value(val))
        for (ent, val) in map_by_ent
        if ent.direction == direction(:to_node)
    )
    pvals_from_node = Dict(
        ent => Dict(:sp_unit_flow => parameter_value(val))
        for (ent, val) in map_by_ent
        if ent.direction == direction(:from_node)
    )
    add_relationship_parameter_values!(unit__to_node, pvals_to_node; merge_values=true)
    add_relationship_parameter_values!(unit__from_node, pvals_from_node; merge_values=true)
end

function _save_sp_solution!(m, win_nb)
    m.ext[:spineopt].sp_values[win_nb] = Dict(
        name => copy(m.ext[:spineopt].values[name])
        for name in keys(m.ext[:spineopt].variables)
        if !occursin("invested", string(name))
    )
end

function _set_sp_solution!(m, win_nb)
    for (name, vals) in get(m.ext[:spineopt].sp_values, win_nb, ())
        var = m.ext[:spineopt].variables[name]
        var isa VariableRef || continue
        for (ind, val) in vals
            set_start_value(var[ind], val)
        end
    end
end

function save_mp_objective_bounds_and_gap!(m_mp)
    obj_lb = m_mp.ext[:spineopt].objective_lower_bound[] = objective_value(m_mp)
    sp_obj_val = sum(values(sp_objective_value_bi(benders_iteration=current_bi)); init=0)
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
