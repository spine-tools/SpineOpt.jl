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

function rerun_spineopt_benders!(
    m,
    url_out;
    add_user_variables,
    add_constraints,
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
    run_kernel,
)
    m_mp = master_problem_model(m)
    @timelog log_level 2 "Creating subproblem temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating master problem temporal structure..." generate_master_temporal_structure!(m_mp)
    @timelog log_level 2 "Creating subproblem stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Creating master problem stochastic structure..." generate_stochastic_structure!(m_mp)
    m_mp.ext[:spineopt].temporal_structure[:sp_windows] = m.ext[:spineopt].temporal_structure[:windows]
    sp_roll_count = m.ext[:spineopt].temporal_structure[:window_count] - 1
    roll_temporal_structure!(m, 1:sp_roll_count)
    init_model!(m; add_user_variables=add_user_variables, add_constraints=add_constraints, log_level=log_level)
    _init_mp_model!(m_mp; log_level=log_level)
    min_benders_iterations = min_iterations(model=m_mp.ext[:spineopt].instance)
    max_benders_iterations = max_iterations(model=m_mp.ext[:spineopt].instance)
    j = 1
    undo_force_starting_investments! = nothing
    while optimize
		@log log_level 0 "\nStarting Benders iteration $j"
        if j == 1
            undo_force_starting_investments! = _force_starting_investments!(m_mp)
        elseif j == 2
            undo_force_starting_investments!()
        end
        optimize_model!(m_mp; log_level=log_level) || break
        @timelog log_level 2 "Processing master problem solution" process_master_problem_solution!(m_mp)
        @timelog log_level 2 "Bringing $(m.ext[:spineopt].instance) back to the first window..." begin
            rewind_temporal_structure!(m)
        end
        run_kernel(
            m;
            log_level=log_level,
            update_names=update_names,
            calculate_duals=true,
            log_prefix="Benders iteration $j - ",
            handle_window_about_to_solve=_set_sp_solution!,
            handle_window_solved=process_subproblem_solution!,
        ) || break
        @timelog log_level 2 "Computing benders gap..." save_mp_objective_bounds_and_gap!(m_mp)
        @log log_level 1 "Benders iteration $j complete"
        @log log_level 1 "Objective lower bound: $(@sprintf("%.5e", m_mp.ext[:spineopt].objective_lower_bound[])); "
        @log log_level 1 "Objective upper bound: $(@sprintf("%.5e", m_mp.ext[:spineopt].objective_upper_bound[])); "
        gap = last(m_mp.ext[:spineopt].benders_gaps)
        @log log_level 1 "Gap: $(@sprintf("%1.4f", gap * 100))%"
        if gap <= max_gap(model=m_mp.ext[:spineopt].instance) && j >= min_benders_iterations
            @log log_level 1 "Benders tolerance satisfied, terminating..."
            break
        end
        if j >= max_benders_iterations
            @log log_level 1 "Maximum number of iterations reached ($j), terminating..."
            break
        end
        @timelog log_level 2 "Add MP cuts..." _add_mp_cuts!(m_mp; log_level=log_level)
        _unfix_history!(m)
        j += 1
        global current_bi = add_benders_iteration(j)
    end
    write_report(m_mp, url_out; alternative=alternative, log_level=log_level)
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
end

"""
Initialize the given model for SpineOpt Master Problem: add variables, add constraints and set objective.
"""
function _init_mp_model!(m; log_level=3)
    @timelog log_level 2 "Adding MP variables...\n" _add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding MP constraints...\n" _add_mp_constraints!(m; log_level=log_level)
    @timelog log_level 2 "Setting MP objective..." _set_mp_objective!(m)
    _init_outputs!(m)
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
    investment_costs = sum(in_window for (in_window, _bw) in values(m.ext[:spineopt].objective_terms))
    @objective(
        m,
        Min,
        + sum(sp_objective_upperbound[t] for (t,) in sp_objective_upperbound_indices(m); init=0)
        + investment_costs
    )
end

function _create_mp_objective_terms!(m)
    for term in objective_terms(m; operations=false)
        func = eval(term)
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

function _unfix_history!(m::Model)
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

