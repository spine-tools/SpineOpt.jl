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

function rerun_spineopt_mp(
    url_out::String;
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false,
)
    mip_solver = _default_mip_solver(mip_solver)
    lp_solver = _default_lp_solver(lp_solver)
    outputs = Dict()
    mp = create_model(mip_solver, use_direct_model, :spineopt_master)
    m = create_model(mip_solver, use_direct_model, :spineopt_operations)
    m.ext[:is_sub_problem] = true
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating $(m.ext[:instance]) temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating $(m.ext[:instance]) stochastic structure..." generate_stochastic_structure!(m)
    @timelog log_level 2 "Creating $(mp.ext[:instance]) temporal structure..." generate_temporal_structure!(mp)
    @timelog log_level 2 "Creating $(mp.ext[:instance]) stochastic structure..." generate_stochastic_structure!(mp)
    init_model!(m; add_constraints=add_constraints, log_level=log_level)
    init_mp_model!(mp; add_constraints=add_constraints, log_level=log_level)
    init_outputs!(m)
    init_outputs!(mp)

    max_benders_iterations = max_iterations(model=mp.ext[:instance])

    j = 1
    while optimize
        @log log_level 0 "Starting Benders iteration $j"
        optimize_model!(mp, mip_solver=mip_solver, lp_solver=lp_solver) || break
        @timelog log_level 2 "Saving master problem results..." save_mp_model_results!(outputs, mp)
        @timelog log_level 2 "Processing master problem solution" process_master_problem_solution(mp)
        k = 1
        while true
            @log log_level 1 "Benders iteration $j - Window $k: $(current_window(m))"
            optimize_model!(m; mip_solver=mip_solver, lp_solver=lp_solver, log_level=log_level) || break
            @timelog log_level 0 "Fixing integer values for final LP to obtain duals..." relax_integer_vars(m)
            if lp_solver != mip_solver
                set_optimizer(m, lp_solver)
            end
            @timelog log_level 0 "Optimizing final LP of $(m.ext[:instance]) to obtain duals..." optimize!(m)
            @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
            @timelog log_level 2 "Saving results..." save_model_results!(outputs, m)
            if lp_solver != mip_solver
                set_optimizer(m, mip_solver)
            end
            @timelog log_level 2 "Setting integers and binaries..." unrelax_integer_vars(m)
            if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
                @timelog log_level 2 " ... Rolling complete\n" break
            end
            update_model!(m; update_constraints=update_constraints, log_level=log_level)
            k += 1
        end
        @timelog log_level 2 "Processing subproblem solution..." process_subproblem_solution(m, mp)

        @log log_level 1 "Benders iteration $j complete. Objective upper bound: "
        @log log_level 1 "$(@sprintf("%.5e",mp.ext[:objective_upper_bound])); "
        @log log_level 1 "Objective lower bound: $(@sprintf("%.5e",mp.ext[:objective_lower_bound])); "
        @log log_level 1 "Gap: $(@sprintf("%1.4f",mp.ext[:benders_gap]*100))%"

        if mp.ext[:benders_gap] <= max_gap(model=mp.ext[:instance])
            @timelog log_level 1 "Benders tolerance satisfied, terminating..." break
        end
        if j >= max_benders_iterations
            @timelog log_level 1 "Maximum number of iterations reached ($j), terminating..." break
        end

        @timelog log_level 2 "Add MP cuts..." add_mp_cuts!(mp; log_level=3)
        msg = "Resetting sub problem temporal structure. Rewinding $(k - 1) times..."
        if @timelog log_level 2 msg reset_temporal_structure(m, k - 1)
            update_model!(m; update_constraints=update_constraints, log_level=log_level)
        end
        j += 1
        global current_bi = add_benders_iteration(j)
    end
    @timelog log_level 2 "Writing report..." write_report(m, url_out)
    m, mp
end

"""
Initialize the given model for SpineOpt Master Problem: add variables, fix the necessary variables,
add constraints and set objective.
"""
function init_mp_model!(mp; add_constraints=mp -> nothing, log_level=3)
    @timelog log_level 2 "Adding MP variables...\n" add_mp_variables!(mp; log_level=log_level)
    @timelog log_level 2 "Fixing MP variable values..." fix_variables!(mp)
    @timelog log_level 2 "Adding MP constraints...\n" add_mp_constraints!(
        mp;
        add_constraints=add_constraints,
        log_level=log_level,
    )
    @timelog log_level 2 "Setting MP objective..." set_mp_objective!(mp)
end

"""
Add SpineOpt Master Problem variables to the given model.
"""
function add_mp_variables!(mp; log_level=3)
    @timelog log_level 3 "- [variable_mp_objective_lowerbound]" add_variable_mp_objective_lowerbound!(mp)
    @timelog log_level 3 "- [variable_mp_units_invested]" add_variable_units_invested!(mp)
    @timelog log_level 3 "- [variable_mp_units_invested_available]" add_variable_units_invested_available!(mp)
    @timelog log_level 3 "- [variable_mp_units_mothballed]" add_variable_units_mothballed!(mp)
    @timelog log_level 3 "- [variable_mp_connections_invested]" add_variable_connections_invested!(mp)
    @timelog log_level 3 "- [variable_mp_connections_invested_available]" add_variable_connections_invested_available!(
        mp,
    )
    @timelog log_level 3 "- [variable_mp_connections_decommissioned]" add_variable_connections_decommissioned!(mp)
    @timelog log_level 3 "- [variable_mp_storages_invested]" add_variable_storages_invested!(mp)
    @timelog log_level 3 "- [variable_mp_storages_invested_available]" add_variable_storages_invested_available!(mp)
    @timelog log_level 3 "- [variable_mp_storages_decommissioned]" add_variable_storages_decommissioned!(mp)
end

"""
Add SpineOpt master problem constraints to the given model.
"""
function add_mp_constraints!(mp; add_constraints=mp -> nothing, log_level=3)
    @timelog log_level 3 "- [constraint_mp_objective]" add_constraint_mp_objective!(mp)
    @timelog log_level 3 "- [constraint_unit_lifetime]" add_constraint_unit_lifetime!(mp)
    @timelog log_level 3 "- [constraint_units_invested_transition]" add_constraint_units_invested_transition!(mp)
    @timelog log_level 3 "- [constraint_units_invested_available]" add_constraint_units_invested_available!(mp)
    @timelog log_level 3 "- [constraint_connection_lifetime]" add_constraint_connection_lifetime!(mp)
    @timelog log_level 3 "- [constraint_connections_invested_transition]" add_constraint_connections_invested_transition!(
        mp,
    )
    @timelog log_level 3 "- [constraint_connections_invested_available]" add_constraint_connections_invested_available!(
        mp,
    )
    @timelog log_level 3 "- [constraint_storage_lifetime]" add_constraint_storage_lifetime!(mp)
    @timelog log_level 3 "- [constraint_storages_invested_transition]" add_constraint_storages_invested_transition!(mp)
    @timelog log_level 3 "- [constraint_storages_invested_available]" add_constraint_storages_invested_available!(mp)

    # Name constraints
    for (con_key, cons) in mp.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key, inds))
        end
    end
end

"""
Update (readd) SpineOpt master problem constraints that involve new objects (update doesn't work).
"""
function add_mp_cuts!(mp; log_level=3)
    @timelog log_level 3 " - [constraint_mp_any_invested_cuts]" add_constraint_mp_any_invested_cuts!(mp)

    # Name constraints
    cons = mp.ext[:constraints][:mp_units_invested_cut]
    for (inds, con) in cons
        set_name(con, string(:mp_units_invested_cut, inds))
    end
end

function save_mp_model_results!(outputs, mp)
    save_variable_values!(mp)
    save_objective_values!(mp)
    save_outputs!(mp)
end
