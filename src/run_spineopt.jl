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

Run SpineOpt using the contents of `url_in` and write report(s) to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Keyword arguments

**`upgrade::Bool=false`**: whether or not to automatically upgrade SpineOpt data structure to latest.

**`mip_solver=nothing`**: a MIP solver to use if no MIP solver specified in the DB.

**`lp_solver=nothing`**: a LP solver to use if no LP solver specified in the DB.

**`add_constraints=m -> nothing`**: a function that receives the `Model` object as argument
and adds custom user constraints.

**`update_constraints=m -> nothing`**: a function that receives the `Model` object as argument
and updates custom user constraints after the model rolls.

**`log_level::Int=3`**: an integer to control the log level.

**`optimize::Bool=true`**: whether or not to optimise the model.

**`update_names::Bool=false`**: whether or not to update variable and constraint names after the model rolls
(expensive)

**`alternative::String=""`**: if non empty, write results to the given alternative in the output DB.

**`write_as_roll::Bool=false`**: whether or not to write results as the model rolls.

**`use_direct_model::Bool=false`**: whether or not to use `JuMP.direct_model` to build the `Model` object.

**`filters::Dict{String,String}=Dict("tool" => "object_activity_control")`**: a dictionary to specify filters.
Possible keys are "tool" and "scenario". Values should be a tool or scenario name in the input DB.
"""
function run_spineopt(
    url_in::String,
    url_out::Union{String,Nothing}=url_in;
    upgrade=false,
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=false,
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
        update_names=update_names,
        alternative=alternative,
        write_as_roll=write_as_roll,
        use_direct_model=use_direct_model
    )
    # FIXME: make sure use_direct_model this works with db solvers
    # possibly adapt union? + allow for conflicts if direct model is used
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
    update_names=false,
    alternative="",
    write_as_roll=false,
    use_direct_model=false,
    alternative_objective=m -> nothing,
)
    m = create_model(:spineopt_standard, mip_solver, lp_solver, use_direct_model)
    mp = create_model(:spineopt_benders_master, mip_solver, lp_solver, use_direct_model)
    m_mga = create_model(:spineopt_mga, mip_solver, lp_solver, use_direct_model)

    Base.invokelatest(
        rerun_spineopt!,
        m,
        mp,
        m_mga,
        url_out;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        update_constraints=update_constraints,
        log_level=log_level,
        optimize=optimize,
        update_names=update_names,
        alternative=alternative,
        write_as_roll=write_as_roll,
        alternative_objective=alternative_objective
    )
end

function rerun_spineopt!(::Nothing, mp, ::Nothing, url_out; kwargs...)
    error("can't run a model of type `spineopt_benders_master` without another of type `spineopt_standard`")
end
function rerun_spineopt!(::Nothing, mp, m_mga; kwargs...)
    error("can't run models of type `spineopt_benders_master` and `spineopt_mga` together")
end
function rerun_spineopt!(m, ::Nothing, m_mga; kwargs...)
    error("can't run models of type `spineopt_standard` and `spineopt_mga` together")
end
function rerun_spineopt!(::Nothing, ::Nothing, ::Nothing; kwargs...)
    error("can't run without at least one model of type `spineopt_standard` or `spineopt_mga`")
end

"""
A JuMP `Model` for SpineOpt.
"""
function create_model(model_type, mip_solver, lp_solver, use_direct_model=false)
    isempty(model(model_type=model_type)) && return nothing
    instance = first(model(model_type=model_type))
    mip_solver = _mip_solver(instance, mip_solver)
    lp_solver = _lp_solver(instance, lp_solver)
    m = Base.invokelatest(_do_create_model, mip_solver, use_direct_model)
    m.ext[:instance] = instance
    m.ext[:variables] = Dict{Symbol,Dict}()
    m.ext[:variables_definition] = Dict{Symbol,Dict}()
    m.ext[:values] = Dict{Symbol,Dict}()
    m.ext[:constraints] = Dict{Symbol,Dict}()
    m.ext[:marginals] = Dict{Symbol,Dict}()
    m.ext[:outputs] = Dict()
    m.ext[:integer_variables] = []
    m.ext[:is_subproblem] = false
    m.ext[:objective_lower_bound] = 0.0
    m.ext[:objective_upper_bound] = 0.0
    m.ext[:benders_gap] = 0.0
    m.ext[:mip_solver] = mip_solver
    m.ext[:lp_solver] = lp_solver
    m
end

_do_create_model(mip_solver, use_direct_model) = use_direct_model ? direct_model(mip_solver()) : Model(mip_solver)

"""
A mip solver for given model instance. If given solver is not `nothing`, just return it.
Otherwise create and return a solver based on db settings for instance.
"""
function _mip_solver(instance, given_solver)
    _solver(given_solver) do
        _db_mip_solver(instance)
    end
end

"""
A lp solver for given model instance. If given solver is not `nothing`, just return it.
Otherwise create and return a solver based on db settings for instance.
"""
function _lp_solver(instance, given_solver)
    _solver(given_solver) do
        _db_lp_solver(instance)
    end
end

_solver(f::Function, given_solver) = given_solver
_solver(f::Function, ::Nothing) = f()

function _db_mip_solver(instance)
    _db_solver(
        db_mip_solver(model=instance, _strict=false),
        db_mip_solver_options(model=instance, _strict=false)
    ) do
        @warn "no `db_mip_solver` parameter was found for model `$instance` - using the default instead"
        optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01)
    end
end

function _db_lp_solver(instance)
    _db_solver(
        db_lp_solver(model=instance, _strict=false),
        db_lp_solver_options(model=instance, _strict=false)
    ) do
        @warn "no `db_lp_solver` parameter was found for model `$instance` - using the default instead"
        optimizer_with_attributes(Clp.Optimizer, "logLevel" => 0)
    end
end

function _db_solver(f::Function, db_solver_name::Symbol, db_solver_options)
    db_solver_mod_name = Symbol(first(splitext(string(db_solver_name))))
    db_solver_options_parsed = _parse_solver_options(db_solver_name, db_solver_options)
    @eval using $db_solver_mod_name
    db_solver_mod = getproperty(@__MODULE__, db_solver_mod_name)
    factory = () -> Base.invokelatest(db_solver_mod.Optimizer)
    optimizer_with_attributes(factory, db_solver_options_parsed...)
end
_db_solver(f::Function, ::Nothing, db_solver_options) = f()

function _parse_solver_options(db_solver_name, db_solver_options::Map)
    [
        (String(key) => _parse_solver_option(val.value))
        for (solver_name, options) in db_solver_options
        if solver_name == db_solver_name
        for (key, val) in options.value
    ]
end
_parse_solver_options(db_solver_name, db_solver_options) = []

_parse_solver_option(value::Number) = isinteger(value) ? convert(Int64, value) : value
_parse_solver_option(value) = string(value)

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
    by_analysis_time_sorted = sort(by_analysis_time)
    TimeSeries(
        [ts for by_time_stamp in values(by_analysis_time_sorted) for ts in keys(by_time_stamp)],
        [val for by_time_stamp in values(by_analysis_time_sorted) for val in values(by_time_stamp)],
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


function objective_terms(m) #FIXME: this should just be benders definind the objective function themselves, not haking into run_spineopt
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
    if (model_type(model=m.ext[:instance]) ==:spineopt_standard || model_type(model=m.ext[:instance]) ==:spineopt_mga)
        if m.ext[:is_subproblem]
            op_terms
        else
            [op_terms; invest_terms]
        end
    elseif model_type(model=m.ext[:instance]) == :spineopt_benders_master
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
            write_parameters(output_params, url; report=string(rpt_name), alternative=alternative, on_conflict="merge")
        end
    end
end

function clear_results!(m)
    for out in output()
        by_entity = get!(m.ext[:outputs], out.name, nothing)
        by_entity === nothing && continue
        empty!(by_entity)
    end
end