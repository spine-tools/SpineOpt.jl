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
    m::Model,
    url_out::Union{String,Nothing};
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    alternative_objective=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    resume_file_path=nothing
)
    m_mp = master_problem_model(m)
    @timelog log_level 2 "Creating subproblem temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating master problem temporal structure..." sp_roll_count = begin
        generate_master_temporal_structure!(m, m_mp)
    end
    @timelog log_level 2 "Creating subproblem stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Creating master problem stochastic structure..." generate_stochastic_structure!(m_mp)
    init_model!(
        m;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        alternative_objective=alternative_objective,
        log_level=log_level
    )
    _init_mp_model!(m_mp; log_level=log_level)
    max_benders_iterations = max_iterations(model=m_mp.ext[:spineopt].instance)
    j = 1
    while optimize
		@log log_level 0 "\nStarting Benders iteration $j"
        optimize_model!(m_mp; log_level=log_level) || break
        @timelog log_level 2 "Processing master problem solution" process_master_problem_solution!(m_mp)
        k = 1
        subproblem_solved = nothing
        @timelog log_level 2 "Bringing $(m.ext[:spineopt].instance) back to the first window..." begin
            if sp_roll_count > 0
                roll_temporal_structure!(m, 1:sp_roll_count; rev=true)
                _update_variable_names!(m)
                _update_constraint_names!(m)
            else
                refresh_temporal_structure!(m)
            end
        end
        while true
            m.ext[:spineopt].temporal_structure[:current_window_number] = k
            @log log_level 1 "\nBenders iteration $j - Window $k: $(current_window(m))"
            subproblem_solved = optimize_model!(m; log_level=log_level, calculate_duals=true)
            subproblem_solved || break
            win_weight = window_weight(model=m.ext[:spineopt].instance, i=k, _strict=false)
            win_weight = win_weight !== nothing ? win_weight : 1.0
            @timelog log_level 2 "Processing subproblem solution..." process_subproblem_solution!(m, win_weight)
            if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m, k)
                @log log_level 2 "... Rolling complete\n"
                save_sp_objective_value_tail!(m, win_weight)
                break
            end
            update_model!(m; log_level=log_level, update_names=update_names)
            k += 1
        end
        subproblem_solved || break
        @timelog log_level 2 "Computing benders gap..." save_mp_objective_bounds_and_gap!(m_mp)
        @log log_level 1 "Benders iteration $j complete"
        @log log_level 1 "Objective lower bound: $(@sprintf("%.5e", m_mp.ext[:spineopt].objective_lower_bound[])); "
        @log log_level 1 "Objective upper bound: $(@sprintf("%.5e", m_mp.ext[:spineopt].objective_upper_bound[])); "
        gaps = m_mp.ext[:spineopt].benders_gaps
        @log log_level 1 "Gap: $(@sprintf("%1.4f", last(gaps) * 100))%"
        if last(gaps) <= max_gap(model=m_mp.ext[:spineopt].instance)
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
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
end

"""
Initialize the given model for SpineOpt Master Problem: add variables, fix the necessary variables,
add constraints and set objective.
"""
function _init_mp_model!(m; log_level=3)
    @timelog log_level 2 "Adding MP variables...\n" _add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Adding MP constraints...\n" _add_mp_constraints!(m; log_level=log_level)
    @timelog log_level 2 "Setting MP objective..." _set_mp_objective!(m)
end

"""
Add SpineOpt Master Problem variables to the given model.
"""
function _add_mp_variables!(m; log_level=3)
    for (name, add_variable!) in (
            ("sp_objective_upperbound", add_variable_sp_objective_upperbound!),
            ("mp_units_invested", add_variable_units_invested!),
            ("mp_units_invested_available", add_variable_units_invested_available!),
            ("mp_units_mothballed", add_variable_units_mothballed!),
            ("mp_connections_invested", add_variable_connections_invested!),
            ("mp_connections_invested_available", add_variable_connections_invested_available!),
            ("mp_connections_decommissioned", add_variable_connections_decommissioned!),
            ("mp_storages_invested", add_variable_storages_invested!),
            ("mp_storages_invested_available", add_variable_storages_invested_available!),
            ("mp_storages_decommissioned", add_variable_storages_decommissioned!),
        )
        @timelog log_level 3 "- [variable_$name]" add_variable!(m)
    end
end

"""
Add SpineOpt master problem constraints to the given model.
"""
function _add_mp_constraints!(m; log_level=3)
    for (name, add_constraint!) in (
            ("constraint_sp_objective_upperbound", _add_constraint_sp_objective_upperbound!),
            ("constraint_unit_lifetime", add_constraint_unit_lifetime!),
            ("constraint_units_invested_transition", add_constraint_units_invested_transition!),
            ("constraint_units_invested_available", add_constraint_units_invested_available!),
            ("constraint_connection_lifetime", add_constraint_connection_lifetime!),
            ("constraint_connections_invested_transition", add_constraint_connections_invested_transition!),
            ("constraint_connections_invested_available", add_constraint_connections_invested_available!),
            ("constraint_storage_lifetime", add_constraint_storage_lifetime!),
            ("constraint_storages_invested_transition", add_constraint_storages_invested_transition!),
            ("constraint_storages_invested_available", add_constraint_storages_invested_available!),
        )
        @timelog log_level 3 "- [constraint_$name]" add_constraint!(m)
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

Minimize total costs
"""
function _set_mp_objective!(m::Model)
    @fetch sp_objective_upperbound = m.ext[:spineopt].variables
    @objective(
        m,
        Min,
        + expr_sum(sp_objective_upperbound[t] for (t,) in sp_objective_upperbound_indices(m); init=0)
        + total_costs(m, anything; operations=false)
    )
end

"""
Add benders cuts to master problem.
"""
function _add_mp_cuts!(m; log_level=3)
    @timelog log_level 3 " - [constraint_mp_any_invested_cuts]" add_constraint_mp_any_invested_cuts!(m)
    # Name constraints
    cons = m.ext[:spineopt].constraints[:mp_any_invested_cut]
    for (inds, con) in cons
        _set_name(con, string(:mp_any_invested_cut, inds))
    end
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
