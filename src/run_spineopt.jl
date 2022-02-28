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

using Cbc
using Clp

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
    url_out::Union{String,Nothing}=url_in;
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
    filters=Dict("tool" => "object_activity_control")
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
    url_out::Union{String,Nothing};
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false
)
    @eval using JuMP

    db_mip_solvers = _db_mip_solvers(mip_solver)
    db_lp_solvers = _db_lp_solvers(lp_solver)

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
        use_direct_model=use_direct_model,
        db_mip_solvers=db_mip_solvers,
        db_lp_solvers=db_lp_solvers
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
    default_url === nothing && return
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

function _db_mip_solvers(::Nothing)
    default_solver = Base.invokelatest(optimizer_with_attributes, Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01)
    _db_solvers(db_mip_solver, db_mip_solver_options, default_solver)
end
_db_mip_solvers(mip_solver) = Dict(m => mip_solver for m in model())

function _db_lp_solvers(::Nothing)
    default_solver = Base.invokelatest(optimizer_with_attributes, Clp.Optimizer, "LogLevel" => 0)
    _db_solvers(db_lp_solver, db_lp_solver_options, default_solver)
end
_db_lp_solvers(lp_solver) = Dict(m => lp_solver for m in model())


"""
    _db_mip_solvers(db_solver, db_solver_options, default_solver)

A Dict mapping models to mip solvers. 

If `mip_solver` is not `nothing`, then it's used for all models.
Otherwise a solver is built using db_mip_solver (and optionally db_mip_solver_options) from the db.
"""
function _db_solvers(db_solver, db_solver_options, default_solver)
    db_solvers = Dict()
    for m in model()
        db_solver_ = db_solver(model=m, _strict=false)
        db_solvers[m] = if db_solver_ === nothing
            @warn "no `$(db_solver.name)` parameter was found for model `$m` - using the default instead"
            default_solver
        else
            db_solver_name = Symbol(first(splitext(string(db_solver_))))
            db_solver_options_ = db_solver_options(model=m, _strict=false)
            db_solver_options_parsed = if db_solver_options_ !== nothing
                [
                    (String(key) => _parse_solver_option(val.value))
                    for (solver, options) in db_solver_options_
                    if solver == db_solver_
                    for (key, val) in options.value
                ]
            else
                []
            end
            @eval using $db_solver_name
            db_solver_mod = getproperty(@__MODULE__, db_solver_name)
            @info "$db_solver_name solver with $(join(db_solver_options_parsed, ", ")) will be used for model `$m`"
            Base.invokelatest(optimizer_with_attributes, db_solver_mod.Optimizer, db_solver_options_parsed...)
        end
    end
    db_solvers
end

_parse_solver_option(value::Number) = isinteger(value) ? convert(Int64, value) : value
_parse_solver_option(value) = string(value)
