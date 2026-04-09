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
"""
Initialize the given model for SpineOpt Master Problem: add variables, add constraints and set objective.
"""
function _build_mp_model!(m; log_level=3)
    num_variables(m) == 0 || return
    _generate_reports_by_output!(m)
    model_name = _model_name(m)
    @timelog log_level 2 "Creating $model_name temporal structure..." generate_master_temporal_structure!(m)
    @timelog log_level 2 "Creating $model_name stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Adding $model_name independent variables...\n" _add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding $model_name dependent variables...\n" _add_dependent_variables!(m; log_level=log_level)
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
function _add_mp_cuts!(m_mp, m; log_level=3)
    for add_constraint! in (
            add_constraint_mp_any_invested_cuts!,
            add_constraint_mp_min_res_gen_to_demand_ratio_cuts!,
        )
        name = name_from_fn(add_constraint!)
        @timelog log_level 3 "- [$name]" add_constraint!(m_mp, m)
    end
    _update_constraint_names!(m_mp)
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

function _init_benders_invested_available!(m_mp, m)
    for var_name in (:units_invested_available, :connections_invested_available, :storages_invested_available)
        var_indices = m_mp.ext[:spineopt].variables_definition[var_name][:indices](m_mp)
        unique_entities = unique(_drop_key(ind, :t) for ind in var_indices)
        model_very_end = maximum(end_.(ind.t for ind in var_indices); init=DateTime(0))
        x_invested_available_by_ent = m_mp.ext[:spineopt].downstream_outputs[var_name] = Dict(
            ent => parameter_value(TimeSeries([model_very_end + Minute(1)], [NaN])) for ent in unique_entities
        )
        isempty(var_indices) && continue
        for m_sp in [m; collect(values(m.ext[:spineopt].model_by_stage))]
            fix_indices_by_ent = Dict()
            for ind in m_sp.ext[:spineopt].variables_definition[var_name][:indices](m_sp)
                ent = _drop_key(ind, :t)
                push!(get!(fix_indices_by_ent, ent, []), ind)
            end
            for (ent, fix_indices) in fix_indices_by_ent
                x_invested_available = x_invested_available_by_ent[ent]
                for ind in fix_indices
                    call_kwargs = (t=ind.t,)
                    call = Call(x_invested_available, call_kwargs, (Symbol(:benders_, var_name), call_kwargs))
                    fix(m_sp.ext[:spineopt].variables[var_name][ind], call)
                end
            end
        end
    end
end

function process_master_problem_solution(m_mp, m)
    _do_save_outputs!(
        m_mp, (:units_invested_available, :connections_invested_available, :storages_invested_available), (;)
    )
    _update_benders_invested_available!(m_mp)
end

function _update_benders_invested_available!(m_mp)
    for (var_name, current_benders_invested_available) in m_mp.ext[:spineopt].downstream_outputs
        new_benders_invested_available = Dict(ent => parameter_value(val) for (ent, val) in _val_by_ent(m_mp, var_name))
        mergewith!(merge!, current_benders_invested_available, new_benders_invested_available)
    end
end

function process_subproblem_solution(m, k)
    win_weight = window_weight(model=m.ext[:spineopt].instance, i=k, _strict=false)
    win_weight = win_weight !== nothing ? win_weight : 1.0
    _wait_for_dual_solves(m)
    _do_save_outputs!(
        m,
        (
            :bound_units_invested_available,
            :bound_connections_invested_available,
            :bound_storages_invested_available,
            :unit_flow,
        ),
        (;);
        weight=win_weight,
    )
    if k == 1
        m.ext[:spineopt].extras[:sp_objective_value_bi] = 0
    end
    m.ext[:spineopt].extras[:sp_objective_value_bi] += win_weight * sum(values(m.ext[:spineopt].values[:total_costs]))
    if _is_last_window(m, k)
        m.ext[:spineopt].extras[:sp_objective_value_bi] += (
            win_weight * sum(values(m.ext[:spineopt].values[:total_costs_tail]))
        )
    end
end

function _is_last_window(m, k)
    k == m.ext[:spineopt].temporal_structure[:window_count]
end

function _val_by_ent(m, var_name)
    _output_value_by_entity(m.ext[:spineopt].outputs[var_name], model_end(model=m.ext[:spineopt].instance))
end

function save_mp_objective_bounds_and_gap!(m_mp, m)
    obj_lb = objective_value(m_mp)
    obj_ub = m.ext[:spineopt].extras[:sp_objective_value_bi] + value(realize(investment_costs(m_mp)))
    gap = (obj_ub == obj_lb) ? 0 : 2 * (obj_ub - obj_lb) / (obj_ub + obj_lb)
    push!(m_mp.ext[:spineopt].benders_gaps, gap)
    push!(m_mp.ext[:spineopt].objective_lower_bounds, obj_lb)
    push!(m_mp.ext[:spineopt].objective_upper_bounds, obj_ub)
end

function investment_costs(m_mp)
    sum(in_window for (in_window, _bw) in values(m_mp.ext[:spineopt].objective_terms))
end

function add_benders_iteration(j)
    new_bi = _make_bi(j)
    add_object!(benders_iteration, new_bi)
    new_bi
end

function _collect_outputs!(
    m, m_mp; log_level, update_names, write_as_roll, output_suffix, log_prefix, calculate_duals
)
    _do_solve_model!(m_mp; log_level, update_names, output_suffix, log_prefix, save_outputs=true)
    _do_solve_model!(
        m;
        log_level,
        update_names,
        write_as_roll,
        output_suffix,
        calculate_duals,
        log_prefix,
        save_outputs=true,
    )
end
