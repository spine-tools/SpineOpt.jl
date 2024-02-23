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

"""
    run_spineopt(url_in, url_out; <keyword arguments>)

Run SpineOpt using the contents of `url_in` and write report(s) to `url_out`.
At least `url_in` must point to a valid Spine database.
Alternatively, `url_in` can be a julia dictionary (e.g. manually created or parsed from a json file).
A new Spine database is created at `url_out` if one doesn't exist.

# Arguments

- `upgrade::Bool=false`: whether or not to automatically upgrade the data structure in `url_in` to latest.

- `mip_solver=nothing`: a MIP solver to use if no MIP solver specified in the DB.

- `lp_solver=nothing`: a LP solver to use if no LP solver specified in the DB.

- `add_constraints=m -> nothing`: a function that receives the `Model` object as argument
  and adds custom user constraints.

- `log_level::Int=3`: an integer to control the log level.

- `optimize::Bool=true`: whether or not to optimise the model (useful for running tests).

- `update_names::Bool=false`: whether or not to update variable and constraint names after the model rolls
  (expensive).

- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.

- `write_as_roll::Int=0`: if greater than 0 and the run has a rolling horizon, then write results every that many
  windows.

- `use_direct_model::Bool=false`: whether or not to use `JuMP.direct_model` to build the `Model` object.

- `filters::Dict{String,String}=Dict("tool" => "object_activity_control")`: a dictionary to specify filters.
  Possible keys are "tool" and "scenario". Values should be a tool or scenario name in the input DB.

- `templates`: a collection of templates to load on top of the SpineOpt template.
  Each template must be a `Dict` with the same structure as the one returned by `SpineOpt.template()`.

- `log_file_path::String=nothing`: if not nothing, log all console output to a file at the given path. The file
  is overwritten at each call.

- `resume_file_path::String=nothing`: only relevant in rolling horizon optimisations with `write_as_roll` greater or
  equal than one. If the file at given path contains resume data from a previous run, start the run from that point.
  Also, save resume data to that same file as the model rolls and results are written to the output database.

- `run_kernel`: a function to call with the model object in order to solve the optimisation problem. It defaults to
  `run_spineopt_kernel!` but another function with the same signature can be provided to extend the current algorithm
  or use a different one. This is intended to develop extensions.

# Example

    using SpineOpt
    m = run_spineopt(
        raw"sqlite:///C:\\path\\to\\your\\inputputdb.sqlite", 
        raw"sqlite:///C:\\path\\to\\your\\outputdb.sqlite";
        filters=Dict("tool" => "object_activity_control", "scenario" => "scenario_to_run"),
        alternative="your_results_alternative"
    )

"""
function run_spineopt(
    url_in::Union{String,Dict},
    url_out::Union{String,Nothing}=url_in;
    upgrade=false,
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    use_direct_model=false,
    filters=Dict("tool" => "object_activity_control"),
    templates=(),
    log_file_path=nothing,
    resume_file_path=nothing,
    run_kernel=run_spineopt_kernel!,
)
    if log_file_path === nothing
        return _run_spineopt(
            url_in,
            url_out;
            upgrade=upgrade,
            mip_solver=mip_solver,
            lp_solver=lp_solver,
            add_user_variables=add_user_variables,
            add_constraints=add_constraints,
            log_level=log_level,
            optimize=optimize,
            update_names=update_names,
            alternative=alternative,
            write_as_roll=write_as_roll,
            use_direct_model=use_direct_model,
            filters=filters,
            templates=templates,
            resume_file_path=resume_file_path,
            run_kernel=run_kernel,
        )
    end
    done = false
    actual_stdout = stdout
    @async begin
        open(log_file_path, "r") do log_file
            while !done
                data = read(log_file, String)
                if !isempty(data)
                    print(actual_stdout, data)
                    flush(actual_stdout)
                end
                yield()
            end
        end
    end
    open(log_file_path, "w") do log_file
        @async while !done
            flush(log_file)
            yield()
        end
        redirect_stdout(log_file) do
            redirect_stderr(log_file) do
                yield()
                try
                    return _run_spineopt(
                        url_in,
                        url_out;
                        upgrade=upgrade,
                        mip_solver=mip_solver,
                        lp_solver=lp_solver,
                        add_user_variables=add_user_variables,
                        add_constraints=add_constraints,
                        log_level=log_level,
                        optimize=optimize,
                        update_names=update_names,
                        alternative=alternative,
                        write_as_roll=write_as_roll,
                        use_direct_model=use_direct_model,
                        filters=filters,
                        templates=templates,
                        resume_file_path=resume_file_path,
                        run_kernel=run_kernel,
                    )
                catch err
                    showerror(log_file, err, stacktrace(catch_backtrace()))
                    rethrow()
                finally
                    done = true
                end
            end
        end
    end
end

function _run_spineopt(url_in, url_out; upgrade, log_level, filters, templates, kwargs...)
    t_start = now()
    @log log_level 1 "\nExecution started at $t_start"
    prepare_spineopt(url_in; upgrade=upgrade, log_level=log_level, filters=filters, templates=templates)
    m = rerun_spineopt(url_out; log_level=log_level, kwargs...)
    t_end = now()
    elapsed_time_string = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(t_end - t_start)))    
    @log log_level 1 "\nExecution complete. Started at $t_start, ended at $t_end, elapsed time: $elapsed_time_string"
    m
    # FIXME: make sure use_direct_model this works with db solvers
    # possibly adapt union? + allow for conflicts if direct model is used
end

function prepare_spineopt(
    url_in;
    upgrade=false,
    log_level=3,
    filters=Dict("tool" => "object_activity_control"),
    templates=(),
)
    @log log_level 0 "Preparing SpineOpt for $(_real_url(url_in))..."
    _check_version(url_in; log_level, upgrade)
    @timelog log_level 2 "Initializing data structure from db..." begin
        template = SpineOpt.template()
        using_spinedb(template, @__MODULE__; extend=false)
        for template in templates
            using_spinedb(template, @__MODULE__; extend=true)
        end
        data = _data(url_in; upgrade, filters)
        using_spinedb(data, @__MODULE__; extend=true)
        missing_items = difference(template, data)
        if !isempty(missing_items)
            println()
            @warn """
            Some items are missing from the input database.
            We'll assume sensitive defaults for any missing parameter definitions,
            and empty collections for any missing classes.
            SpineOpt might still be able to run, but otherwise you'd need to check your input database.

            Missing item list follows:
            $missing_items
            """
        end
    end
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
end

_real_url(url_in::String) = run_request(url_in, "get_db_url")
_real_url(::Dict) = "dictionary data"

function _check_version(url_in::String; log_level, upgrade)
    version = find_version(url_in)
    if version < current_version()
        if !upgrade
            @warn """
            The data structure is not the latest version.
            SpineOpt might still be able to run, but results aren't guaranteed.
            Please use `run_spineopt(url_in; upgrade=true)` to upgrade.
            """
        else
            _do_upgrade_db(url_in, version; log_level)
        end
    end
end
_check_version(data::Dict; kwargs...) = nothing

function _do_upgrade_db(url_in, version; log_level)
    @log log_level 0 "Upgrading data structure to the latest version... "
    run_migrations(url_in, version, log_level)
    @log log_level 0 "Done!"
end

_data(url_in::String; upgrade, filters) = export_data(url_in; upgrade=upgrade, filters=filters)
_data(data::Dict; kwargs...) = data

function rerun_spineopt(
    url_out::Union{String,Nothing};
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    resume_file_path=nothing,
    use_direct_model=false,
    run_kernel=run_spineopt_kernel!,
)
    @log log_level 0 "Running SpineOpt..."
    m = create_model(mip_solver, lp_solver, use_direct_model)
    rerun_spineopt! = Dict(
        :spineopt_standard => rerun_spineopt_standard!,
        :spineopt_benders => rerun_spineopt_benders!,
        :spineopt_mga => rerun_spineopt_mga!
    )[model_type(model=m.ext[:spineopt].instance)]
    # NOTE: invokelatest ensures that solver modules are available to use by JuMP
    Base.invokelatest(        
        rerun_spineopt!,
        m,
        url_out;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        log_level=log_level,
        optimize=optimize,
        update_names=update_names,
        alternative=alternative,
        write_as_roll=write_as_roll,
        resume_file_path=resume_file_path,
        run_kernel=run_kernel,
    )
end

"""
A JuMP `Model` for SpineOpt.
"""
function create_model(mip_solver, lp_solver, use_direct_model=false)
    instance = first(model())
    mip_solver = _mip_solver(instance, mip_solver)
    lp_solver = _lp_solver(instance, lp_solver)
    m = Base.invokelatest(_do_create_model, mip_solver, use_direct_model)
    m_mp = if model_type(model=instance) === :spineopt_benders
        m_mp = Base.invokelatest(_do_create_model, mip_solver, use_direct_model)
        m_mp.ext[:spineopt] = SpineOptExt(instance, lp_solver)
        m_mp
    end
    m.ext[:spineopt] = SpineOptExt(instance, lp_solver, m_mp)
    m
end

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
        optimizer_with_attributes(HiGHS.Optimizer, "presolve" => "on", "output_flag" => false, "mip_rel_gap" => 0.01)
    end
end

function _db_lp_solver(instance)
    _db_solver(
        db_lp_solver(model=instance, _strict=false),
        db_lp_solver_options(model=instance, _strict=false)
    ) do
        @warn "no `db_lp_solver` parameter was found for model `$instance` - using the default instead"
        optimizer_with_attributes(HiGHS.Optimizer, "presolve" => "on", "output_flag" => false)
    end
end

function _db_solver(f::Function, db_solver_name::Symbol, db_solver_options)
    db_solver_mod_name = Symbol(first(splitext(string(db_solver_name))))
    db_solver_options_parsed = _parse_solver_options(db_solver_name, db_solver_options)
    db_solver_mod = try
        @eval Base.Main using $db_solver_mod_name
        getproperty(Base.Main, db_solver_mod_name)
    catch
        @eval using $db_solver_mod_name
        getproperty(@__MODULE__, db_solver_mod_name)
    end
    factory = () -> Base.invokelatest(db_solver_mod.Optimizer)
    optimizer_with_attributes(factory, db_solver_options_parsed...)
end
_db_solver(f::Function, ::Nothing, db_solver_options) = f()

function _parse_solver_options(db_solver_name, db_solver_options::Map)
    [
        (String(key) => _parse_solver_option(val))
        for (solver_name, options) in db_solver_options
        if solver_name == db_solver_name
        for (key, val) in options
    ]
end
_parse_solver_options(db_solver_name, db_solver_options) = []

_parse_solver_option(value::Bool) = value
_parse_solver_option(value::Number) = isinteger(value) ? convert(Int64, value) : value
_parse_solver_option(value) = string(value)

_do_create_model(mip_solver, use_direct_model) = use_direct_model ? direct_model(mip_solver) : Model(mip_solver)

struct SpineOptExt
    instance::Object
    lp_solver
    master_problem_model::Union{Model,Nothing}
    intermediate_results_folder::String
    report_name_keys_by_url::Dict
    reports_by_output::Dict
    variables::Dict{Symbol,Dict}
    variables_definition::Dict{Symbol,Dict}
    values::Dict{Symbol,Dict}
    sp_values::Dict{Int64,Dict}
    constraints::Dict{Symbol,Dict}
    objective_terms::Dict{Symbol,Any}
    outputs::Dict{Symbol,Union{Dict,Nothing}}
    temporal_structure::Dict
    stochastic_structure::Dict
    dual_solves::Array{Any,1}
    dual_solves_lock::ReentrantLock
    objective_lower_bound::Base.RefValue{Float64}
    objective_upper_bound::Base.RefValue{Float64}
    benders_gaps::Vector{Float64}
    has_results::Base.RefValue{Bool}
    function SpineOptExt(instance, lp_solver=nothing, master_problem_model=nothing)
        intermediate_results_folder = tempname(; cleanup=false)
        mkpath(intermediate_results_folder)
        report_name_keys_by_url = Dict()
        for rpt in model__report(model=instance)
            keys = [
                (out.name, overwrite_results_on_rolling(report=rpt, output=out))
                for out in report__output(report=rpt)
            ]
            output_url = output_db_url(report=rpt, _strict=false)
            push!(get!(report_name_keys_by_url, output_url, []), (rpt.name, keys))
        end
        reports_by_output = Dict()
        for rpt in model__report(model=instance), out in report__output(report=rpt)
            push!(get!(reports_by_output, out, []), rpt)
        end
        new(
            instance,
            lp_solver,
            master_problem_model,
            intermediate_results_folder,
            report_name_keys_by_url,
            reports_by_output,
            Dict{Symbol,Dict}(),  # variables
            Dict{Symbol,Dict}(),  # variables_definition
            Dict{Symbol,Dict}(),  # values
            Dict{Int64,Dict}(),  # sp_values
            Dict{Symbol,Dict}(),  # constraints            
            Dict{Symbol,Any}(),  # objective_terms
            Dict{Symbol,Union{Dict,Nothing}}(),  # outputs
            Dict(),  # temporal_structure
            Dict(),  # stochastic_structure
            [],  # dual_solves
            ReentrantLock(),  # dual_solves_lock
            Ref(0.0),  # objective_lower_bound
            Ref(0.0),  # objective_upper_bound
            [],  # benders_gaps
            Ref(false),  # has_results
        )
    end
end

JuMP.copy_extension_data(data::SpineOptExt, new_model::AbstractModel, model::AbstractModel) = nothing

master_problem_model(m) = m.ext[:spineopt].master_problem_model

function upgrade_db(url_in; log_level)
    version = find_version(url_in)
    if version < current_version()
        _do_upgrade_db(url_in, version; log_level)
    end
end