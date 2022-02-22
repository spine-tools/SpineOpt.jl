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
    @log(level, threshold, msg)
"""
macro log(level, threshold, msg)
    quote
        if $(esc(level)) >= $(esc(threshold))
            printstyled($(esc(msg)), "\n"; bold=true)
        end
    end
end

"""
    @timelog(level, threshold, msg, expr)
"""
macro timelog(level, threshold, msg, expr)
    quote
        if $(esc(level)) >= $(esc(threshold))
            @timemsg $(esc(msg)) $(esc(expr))
        else
            $(esc(expr))
        end
    end
end

"""
    @timemsg(msg, expr)
"""
macro timemsg(msg, expr)
    quote
        printstyled($(esc(msg)); bold=true)
        @time $(esc(expr))
    end
end

module _Template
using SpineInterface
end
using ._Template

function _empty_data_structure()
    for items in (object_classes, relationship_classes, parameters)
        for x in items(@__MODULE__)
            empty!(x)
        end
    end
end

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
function run_spineopt(
    url_in::String,
    url_out::String=url_in;
    upgrade=false,
    mip_solver=nothing,
    lp_solver=nothing,
    cleanup=true,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false,
    filters=Dict("tool" => "object_activity_control"),
    use_db_solver_options=false
)
    @log log_level 0 "Running SpineOpt for $(url_in)..."
    version = find_version(url_in)
    if version < current_version()
        if !upgrade
            @warn """
            The data structure is not the latest version.
            SpineOpt might still be able to run, but results aren't guaranteed.
            Please use `run_spineopt(url_in; upgrade=true)` to upgrade.
            """
        else
            @log log_level 0 "Upgrading data structure to the latest version... "
            run_migrations(url_in, version, log_level)
            @log log_level 0 "Done!"
        end
    end
    @timelog log_level 2 "Initializing data structure from db..." begin
        _empty_data_structure()
        using_spinedb(SpineOpt.template(), _Template)
        using_spinedb(url_in, @__MODULE__; upgrade=upgrade, filters=filters)
        missing_items = difference(_Template, @__MODULE__)
        if !isempty(missing_items)
            println()
            @warn """
            Some items are missing from the input database.
            We'll assume sensitive defaults for any missing parameter definitions, and empty collections for any missing classes.
            SpineOpt might still be able to run, but otherwise you'd need to check your input database.

            Missing item list follows:
            $missing_items
            """
        end
    end

    use_db_solver_options && ((mip_solver, lp_solver) = set_db_solvers())

    rerun_spineopt(
        url_out;
        mip_solver=mip_solver,
        lp_solver=lp_solver,
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        update_constraints=update_constraints,
        log_level=log_level,
        optimize=optimize,
        use_direct_model=use_direct_model
    )
end

function rerun_spineopt(
    url_out::String;
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false
)

    # High-level algorithm selection. For now, selecting based on defined model types,
    # but may want more robust system in future
    rerun_spineopt = !isempty(model(model_type=:spineopt_master)) ? rerun_spineopt_mp : rerun_spineopt_sp
    Base.invokelatest(
        rerun_spineopt,
        url_out;
        mip_solver=mip_solver,
        lp_solver=lp_solver,
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        update_constraints=update_constraints,
        log_level=log_level,
        optimize=optimize,
        use_direct_model=use_direct_model
    )
end

"""
    output_value(by_analysis_time, overwrite_results_on_rolling)

A value from a SpineOpt result.

# Arguments
- `by_analysis_time::Dict`: mapping analysis times, to timestamps, to values.
- `overwrite_results_on_rolling::Bool`: if `true`, ignore the analysis times and return a `TimeSeries`.
    If `false`, return a `Map` where the topmost keys are the analysis times.
"""
function output_value(by_analysis_time, overwrite_results_on_rolling::Bool)
    output_value(by_analysis_time, Val(overwrite_results_on_rolling))
end
function output_value(by_analysis_time, overwrite_results_on_rolling::Val{true})
    TimeSeries(
        [ts for by_time_stamp in values(by_analysis_time) for ts in keys(by_time_stamp)],
        [val for by_time_stamp in values(by_analysis_time) for val in values(by_time_stamp)],
        false,
        false
    )
end
function output_value(by_analysis_time, overwrite_results_on_rolling::Val{false})
    Map(
        collect(keys(by_analysis_time)),
        [
            TimeSeries(collect(keys(by_time_stamp)), collect(values(by_time_stamp)), false, false)
            for by_time_stamp in values(by_analysis_time)
        ]
    )
end

function _output_value_by_entity(by_entity, overwrite_results_on_rolling, output_value=output_value)
    Dict(
        entity => output_value(by_analysis_time, Val(overwrite_results_on_rolling))
        for (entity, by_analysis_time) in by_entity
    )
end


function objective_terms(m)
    # if we have a decomposed structure, master problem costs (investments) should not be included
    invest_terms = [:unit_investment_costs, :connection_investment_costs, :storage_investment_costs]
    op_terms = [
        :variable_om_costs,
        :fixed_om_costs,
        :taxes,
        :fuel_costs,
        :start_up_costs,
        :shut_down_costs,
        :objective_penalties,
        :connection_flow_costs,
        :renewable_curtailment_costs,
        :res_proc_costs,
        :ramp_costs,
        :units_on_costs,
    ]
    if model_type(model=m.ext[:instance]) == :spineopt_operations
        if m.ext[:is_subproblem]
            op_terms
        else
            [op_terms; invest_terms]
        end
    elseif model_type(model=m.ext[:instance]) == :spineopt_master
        invest_terms
    end
end

"""
    write_report(m, default_url, output_value=output_value; alternative="")

Write report from given model into a db.

# Arguments
- `m::Model`: a JuMP model resulting from running SpineOpt successfully.
- `default_url::String`: a db url to write the report to.
- `output_value`: a function to replace `SpineOpt.output_value` if needed.

# Keyword arguments
- `alternative::String`: an alternative to pass to `SpineInterface.write_parameters`.
"""
function write_report(m, default_url, output_value=output_value; alternative="")
    reports = Dict()
    outputs = Dict()
    for rpt in model__report(model=m.ext[:instance])
        for out in report__output(report=rpt)
            by_entity = get!(m.ext[:outputs], out.name, nothing)
            by_entity === nothing && continue
            output_url = output_db_url(report=rpt, _strict=false)
            url = output_url !== nothing ? output_url : default_url
            url_reports = get!(reports, url, Dict())
            output_params = get!(url_reports, rpt.name, Dict{Symbol,Dict{NamedTuple,Any}}())
            parameter_name = out.name in objective_terms(m) ? Symbol("objective_", out.name) : out.name
            overwrite = overwrite_results_on_rolling(report=rpt, output=out)
            output_params[parameter_name] = _output_value_by_entity(by_entity, overwrite, output_value)
        end
    end
    for (url, url_reports) in reports
        for (rpt_name, output_params) in url_reports
            write_parameters(output_params, url; report=string(rpt_name), alternative=alternative)
        end
    end
end

function set_db_solvers()

    db_mip_solver_pkg = Symbol("HiGHS")
    @eval using $db_mip_solver_pkg
    db_mip_solver_mod = getproperty(@__MODULE__, db_mip_solver_pkg)
    @info "setting MIP Solver" @__MODULE__
    mip_solver = optimizer_with_attributes(db_mip_solver_mod.Optimizer)
    return (mip_solver, mip_solver)

end

function set_db_solvers_2()   

    db_mip_solver_val = db_mip_solver(model=first(model()))
    db_mip_solver_pkg = Symbol(SubString(string(db_mip_solver_val), 1, length(string(db_mip_solver_val))-3) )
    db_mip_solver_options_val = db_mip_solver_options(model=first(model()))
    
    
    if db_mip_solver_options_val !== nothing 
        db_mip_solver_options_dict = Dict(String(key) => val.value for (key, val) in db_mip_solver_options_val)
    else
        db_mip_solver_options_dict = Dict()
    end
    

    db_lp_solver_val = db_lp_solver(model=first(model()))
    db_lp_solver_pkg = Symbol(SubString(string(db_lp_solver_val), 1, length(string(db_lp_solver_val))-3))
    db_lp_solver_options_val = db_lp_solver_options(model=first(model()))

    if db_lp_solver_options_val !== nothing
        db_lp_solver_options_dict =  Dict(String(key) => val.value for (key, val) in db_lp_solver_options_val)
    else
        db_lp_solver_options_dict = Dict()
    end
    db_mip_solver_pkg = Symbol("CPLEX")
    @eval using $db_mip_solver_pkg
    db_mip_solver_mod = getproperty(@__MODULE__, db_mip_solver_pkg)
    @info "setting MIP Solver" @__MODULE__
    mip_solver = optimizer_with_attributes(db_mip_solver_mod.Optimizer)

    #mip_solver = optimizer_with_attributes(
	#	db_mip_solver_mod.Optimizer,
	#	db_mip_solver_options_dict...
	#)
    
    if db_lp_solver_val == db_mip_solver_val
        db_lp_solver_pkg = db_mip_solver_pkg
        db_lp_solver_mod = db_mip_solver_mod
    else
        @eval using $db_lp_solver_pkg
        db_lp_solver_mod = getproperty(@__MODULE__, db_lp_solver_pkg)
    end
  
    @info "setting LP Solver"
    lp_solver = optimizer_with_attributes(
		db_lp_solver_mod.Optimizer,
		db_lp_solver_options_dict...
	)
    return mip_solver, lp_solver
end