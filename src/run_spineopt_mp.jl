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

**`add_constraints=m -> nothing`** is called with the `Model` object in the first optimization window, and allows adding user contraints.

**`update_constraints=m -> nothing`** is called in windows 2 to the last, and allows updating contraints added by `add_constraints`.

**`log_level=3`** is the log level.
"""
function run_spineopt_mp(
    url_in::String,
    url_out::String=url_in;
    upgrade=false,
    with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
    cleanup=true,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false
)
@log log_level 0 "Running SpineOpt for $(url_in)..."
@timelog log_level 2 "Initializing data structure from db..." begin
    using_spinedb(url_in, @__MODULE__; upgrade=upgrade)
    generate_missing_items()
end
@timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
@timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
rerun_spineopt(
    url_out;
    with_optimizer=with_optimizer,
    add_constraints=add_constraints,
    update_constraints=update_constraints,
    log_level=log_level,
    optimize=optimize,
    use_direct_model=use_direct_model
)
end

function rerun_spineopt_mp(
    url_out::String;
    with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false
)
outputs = Dict()
mp = create_model(with_optimizer, use_direct_model,:spineopt_master)
m = create_model(with_optimizer, use_direct_model,:spineopt_operations)
@timelog log_level 2 "Creating master problem temporal structure..." generate_temporal_structure!(mp)
@timelog log_level 2 "Creating operations problem temporal structure..." generate_temporal_structure!(m)
@timelog log_level 2 "Creating master problem stochastic structure..." generate_stochastic_structure(mp)
@timelog log_level 2 "Creating operations problem stochastic structure..." generate_stochastic_structure(m)    
@log log_level 1 "Window 1: $(current_window(m))"
init_model!(m; add_constraints=add_constraints, log_level=log_level)
init_model!(mp; add_constraints=add_mp_constraints, log_level=log_level)

j = 1
k = 1
while _optimize_mp_model!(mp) # master problem loop       
    @logtime level2 "Processing master problem solution" process_master_problem_solution(mp)
    if j > 1  
        @timelog level2 "Resetting sub problem temporal structure..." reset_temporal_structure(k-1)        
        update_model!(m; update_constraints=update_constraints, log_level=log_level)            
    end 
    k = 2
    while optimize && optimize_model!(m; log_level=log_level)
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving results..." save_model_results!(outputs, m)
        @timelog log_level 2 "Rolling temporal structure..." roll_temporal_structure!(m) || break
        @log log_level 1 "Window $k: $(current_window(m))"
        update_model!(m; update_constraints=update_constraints, log_level=log_level)
        k += 1
    end        
    update_mp_model!(m; update_constraints=update_constraints, log_level=log_level)
end
@timelog log_level 2 "Writing report..." write_report(m, outputs, url_out)
m
end



"""
Add SpineOpt Master Problem variables to the given model.
"""
function add_mp_variables!(m; log_level=3)
    @timelog level3 "- [variable_mp_objective_lowerbound]" add_variable_mp_objective_lowerbound!(m)
    @timelog level3 "- [variable_mp_units_invested]" add_variable_mp_units_invested!(m)
    @timelog level3 "- [variable_mp_units_invested_available]" add_variable_mp_units_invested_available!(m)
    @timelog level3 "- [variable_mp_units_mothballed]" add_variable_mp_units_mothballed!(m)
end


"""
Initialise Master Problem.
"""
function init_mp_model!(m; add_constraints=m -> nothing, log_level=3)
    @timelog log_level 2 "Preprocessing model data structure...\n" preprocess_model_data_structure(m)
    @timelog log_level 2 "Adding variables...\n" add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Fixing variable values..." fix_variables!(m)
    @timelog log_level 2 "Adding constraints...\n" add_mp_constraints!(
        m; add_constraints=add_constraints, log_level=log_level
    )
    @timelog log_level 2 "Setting objective..." set_mp_objective!(m)
end


"""
Add SpineOpt master problem constraints to the given model.
"""
function add_mp_constraints!(m; add_constraints=m -> nothing, log_level=3)
    @logtime level3 "- [constraint_mp_units_invested_cuts]" add_constraint_mp_units_invested_cuts!(m)
    @logtime level3 "- [constraint_mp_objective]" add_constraint_mp_objective!(m)

    # Name constraints
    for (con_key, cons) in m.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key,inds))
        end
    end
end


"""
Initialize the given model for SpineOpt: add variables, fix the necessary variables, add constraints and set objective.
"""
function init_mp_model!(m; add_constraints=m -> nothing, log_level=3)
    @timelog log_level 2 "Adding MP variables...\n" add_mp_variables!(m; log_level=log_level)
    @timelog log_level 2 "Fixing MP variable values..." fix_variables!(m)
    @timelog log_level 2 "Adding MP constraints...\n" add_mp_constraints!(
        m; add_constraints=add_constraints, log_level=log_level
    )
    @timelog log_level 2 "Setting MP objective..." set_mp_objective!(m)
end
