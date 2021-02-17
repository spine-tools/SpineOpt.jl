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
function run_spineopt_mp(
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
end

function rerun_spineopt_mp(
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
    mp = create_model(mip_solver, use_direct_model, :spineopt_master)
    m = create_model(mip_solver, use_direct_model, :spineopt_operations)
    m.ext[:is_sub_problem] = true
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating operations temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating master temporal structure..." generate_temporal_structure!(mp)
    @timelog log_level 2 "Creating operations stochastic structure..." generate_stochastic_structure(m)
    @timelog log_level 2 "Creating master stochastic structure..." generate_stochastic_structure(mp)
    @log log_level 1 "Window 1: $(current_window(m))"
    init_model!(m; add_constraints=add_constraints, log_level=log_level)
    init_mp_model!(mp; add_constraints=add_constraints, log_level=log_level)
    duals_calculation_needed(m) 
    duals_calculation_needed(mp) 

    max_benders_iterations = max_iterations(model=mp.ext[:instance])

    j = 1
    k = 1
    while optimize
        global current_bi
        @log log_level 0 "Starting Master Problem iteration $j"
        j > 1 && (current_bi = add_benders_iteration(j))
        (optimize_model!(mp, mip_solver=mip_solver, lp_solver=lp_solver) && j <= max_benders_iterations) || break
        @timelog log_level 2 "Saving master problem results..." save_mp_model_results!(outputs, mp)
        @timelog log_level 2 "Processing master problem solution" process_master_problem_solution(mp)
        if j == 1
            @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
        else
            msg = "Resetting sub problem temporal structure. Rewinding $(k-1) times..."
            @timelog log_level 2 msg reset_temporal_structure(m, k - 1)
            @log log_level 1 "Window 1: $(current_window(m))"
            set_optimizer(m, mip_solver)
            update_model!(m; update_constraints=update_constraints, log_level=log_level)
        end
        k = 1
        while optimize &&
            optimize_model!(m; mip_solver=mip_solver, lp_solver=lp_solver, log_level=log_level, calculate_duals=true)
            @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
            @timelog log_level 2 "Saving results..." save_model_results!(outputs, m)
            @timelog log_level 2 "Rolling temporal structure..." roll_temporal_structure!(m) ||
                                                                 @timelog log_level 2 " ... Rolling complete\n" break
            @log log_level 1 "Operations window $(k+1), benders iteration $j : $(current_window(m))"
            # we have to do this here because too early and we can't access the solution and too late,
            # we can't add integers/binaries
            set_optimizer(m, mip_solver)
            update_model!(m; update_constraints=update_constraints, log_level=log_level)
            k += 1
        end
        @timelog log_level 2 "Processing operational problem solution..." process_subproblem_solution(m, mp, j)

        @log log_level 1 "Benders iteration $j complete. Objective upper bound: "
        @log log_level 1 "$(@sprintf("%.5e",mp.ext[:objective_upper_bound])); "
        @log log_level 1 "Objective lower bound: $(@sprintf("%.5e",mp.ext[:objective_lower_bound])); "
        @log log_level 1 "Gap: $(@sprintf("%1.4f",mp.ext[:benders_gap]*100))%"

        mp.ext[:benders_gap] <= max_gap(model=mp.ext[:instance]) &&
            @timelog log_level 1 "Benders tolerance satisfied, terminating..." break

        update_model!(mp; update_constraints=update_constraints, log_level=log_level)
        @timelog log_level 2 "Add MP cuts..." add_mp_cuts!(mp; log_level=3)
        j += 1
    end
    @timelog log_level 2 "Writing report..." write_report(m, url_out)
    m, mp
end


"""
Initialize the given model for SpineOpt Master Problem: add variables, fix the necessary variables, 
add constraints and set objective.
"""
function init_mp_model!(m; add_constraints=m -> nothing, log_level=3)
    @timelog log_level 2 "Adding MP variables...\n" add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Fixing MP variable values..." fix_variables!(m)
    @timelog log_level 2 "Adding MP constraints...\n" add_mp_constraints!(
        m;
        add_constraints=add_constraints,
        log_level=log_level,
    )
    @timelog log_level 2 "Setting MP objective..." set_mp_objective!(m)
end


"""
Add SpineOpt Master Problem variables to the given model.
"""
function add_mp_variables!(m; log_level=3)
    @timelog log_level 3 "- [variable_mp_objective_lowerbound]" add_variable_mp_objective_lowerbound!(m)
    @timelog log_level 3 "- [variable_mp_units_invested]" add_variable_units_invested!(m)
    @timelog log_level 3 "- [variable_mp_units_invested_available]" add_variable_units_invested_available!(m)
    @timelog log_level 3 "- [variable_mp_units_mothballed]" add_variable_units_mothballed!(m)
    @timelog log_level 3 "- [variable_mp_connections_invested]" add_variable_connections_invested!(m)
    @timelog log_level 3 "- [variable_mp_connections_invested_available]" add_variable_connections_invested_available!(m)
    @timelog log_level 3 "- [variable_mp_connections_decommissioned]" add_variable_connections_decommissioned!(m)
    @timelog log_level 3 "- [variable_mp_storages_invested]" add_variable_storages_invested!(m)
    @timelog log_level 3 "- [variable_mp_storages_invested_available]" add_variable_storages_invested_available!(m)
    @timelog log_level 3 "- [variable_mp_storages_decommissioned]" add_variable_storages_decommissioned!(m)
end


"""
Add SpineOpt master problem constraints to the given model.
"""
function add_mp_constraints!(m; add_constraints=m -> nothing, log_level=3)

    @timelog log_level 3 "- [constraint_mp_objective]" add_constraint_mp_objective!(m)
    @timelog log_level 3 "- [constraint_unit_lifetime]" add_constraint_unit_lifetime!(m)
    @timelog log_level 3 "- [constraint_units_invested_transition]" add_constraint_units_invested_transition!(m)
    @timelog log_level 3 "- [constraint_units_invested_available]" add_constraint_units_invested_available!(m)
    @timelog log_level 3 "- [constraint_connection_lifetime]" add_constraint_connection_lifetime!(m)
    @timelog log_level 3 "- [constraint_connections_invested_transition]" add_constraint_connections_invested_transition!(m)
    @timelog log_level 3 "- [constraint_connections_invested_available]" add_constraint_connections_invested_available!(m)
    @timelog log_level 3 "- [constraint_storage_lifetime]" add_constraint_storage_lifetime!(m)
    @timelog log_level 3 "- [constraint_storages_invested_transition]" add_constraint_storages_invested_transition!(m)
    @timelog log_level 3 "- [constraint_storages_invested_available]" add_constraint_storages_invested_available!(m)

    # Name constraints
    for (con_key, cons) in m.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key, inds))
        end
    end
end


"""
Update (readd) SpineOpt master problem constraints that involve new objects (update doesn't work).
"""
function add_mp_cuts!(m; log_level=3)

    @timelog log_level 3 " - [constraint_mp_units_invested_cuts]" add_constraint_mp_units_invested_cuts!(m)

    # Name constraints
    cons = m.ext[:constraints][:mp_units_invested_cut]
    for (inds, con) in cons
        set_name(con, string(:mp_units_invested_cut, inds))
    end
end


function save_mp_model_results!(outputs, m)
    save_variable_values!(m)
    save_objective_values!(m)
    save_outputs!(m)
end
