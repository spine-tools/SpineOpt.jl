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
    add_variable!(m::Model, name::Symbol, indices::Function; <keyword arguments>)

Add a variable to `m`, with given `name` and indices given by interating over `indices()`.

# Arguments

  - `lb::Union{Function,Nothing}=nothing`: given an index, return the lower bound.
  - `ub::Union{Function,Nothing}=nothing`: given an index, return the upper bound.
  - `bin::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be binary
  - `int::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be integer
  - `fix_value::Union{Function,Nothing}=nothing`: given an index, return a fix value for the variable or nothing
  - `non_anticipativity_time::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity time or nothing
  - `non_anticipativity_margin::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity margin or nothing
"""
function add_variable!(
    m::Model,
    name::Symbol,
    indices::Function;
    bin::Union{Function,Nothing}=nothing,
    int::Union{Function,Nothing}=nothing,
    lb::Union{Constant,Parameter,Nothing}=nothing,
    ub::Union{Constant,Parameter,Nothing}=nothing,
    initial_value::Union{Parameter,Nothing}=nothing,
    fix_value::Union{Parameter,Nothing}=nothing,
    internal_fix_value::Union{Parameter,Nothing}=nothing,
    replacement_value::Union{Function,Nothing}=nothing,
    non_anticipativity_time::Union{Parameter,Nothing}=nothing,
    non_anticipativity_margin::Union{Parameter,Nothing}=nothing,
)
    m.ext[:spineopt].variables_definition[name] = Dict{Symbol,Union{Function,Parameter,Nothing}}(
        :indices => indices,
        :bin => bin,
        :int => int,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin
    )
    var = m.ext[:spineopt].variables[name] = Dict(
        ind => _variable(
            m,
            name,
            ind,
            bin,
            int,
            lb,
            ub,
            fix_value,
            internal_fix_value,
            replacement_value
        )
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
    )
    # Apply initial value, but make sure it updates itself by using a TimeSeries Call
    if initial_value !== nothing
        last_history_t = last(history_time_slice(m))
        t = model_start(model=m.ext[:spineopt].instance)
        dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
        for (ind, v) in var
            overlaps(ind.t, last_history_t) || continue
            val = initial_value(; ind..., _strict=false)
            val === nothing && continue
            initial_value_ts = parameter_value(TimeSeries([t - dur_unit(1), t], [val, NaN]))
            fix(v, Call(initial_value_ts, (t=ind.t,)))
        end
    end
    merge!(var, _representative_periods_mapping(m, var, indices))
end

"""
    _representative_index(ind)

The representative index corresponding to the given one.
"""
function _representative_index(m, ind, indices)
    representative_t = representative_time_slice(m, ind.t)
    representative_inds = indices(m; ind..., t=representative_t)
    first(representative_inds)
end

"""
    _representative_periods_mapping(v::Dict{VariableRef}, indices::Function)

A `Dict` mapping non representative indices to the variable for the representative index.
"""
function _representative_periods_mapping(m::Model, var::Dict, indices::Function)
    # By default, `indices` skips represented time slices for operational variables other than node_state,
    # as well as for investment variables. This is done by setting the default value of the `temporal_block` argument
    # to `temporal_block(representative_periods_mapping=nothing)` - so any blocks that define a mapping are ignored.
    # To include represented time slices, we need to specify `temporal_block=anything`.
    # Note that for node_state and investment variables, `represented_indices`, below, will be empty.
    representative_indices = indices(m)
    all_indices = indices(m, temporal_block=anything)
    represented_indices = setdiff(all_indices, representative_indices)
    Dict(ind => var[_representative_index(m, ind, indices)] for ind in represented_indices)
end

_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

function _variable(m, name, ind, bin, int, lb, ub, fix_value, internal_fix_value, replacement_value)
    if replacement_value !== nothing
        ind_ = (analysis_time=_analysis_time(m), ind...)
        value = replacement_value(ind_)
        if value !== nothing
            return value
        end
    end
    var = @variable(m, base_name = _base_name(name, ind))
    ind = (analysis_time=_analysis_time(m), ind...)
    bin !== nothing && bin(ind) && set_binary(var)
    int !== nothing && int(ind) && set_integer(var)
    lb === nothing || set_lower_bound(var, lb[(; ind..., _strict=false)])
    ub === nothing || set_upper_bound(var, ub[(; ind..., _strict=false)])
    fix_value === nothing || fix(var, fix_value[(; ind..., _strict=false)])
    internal_fix_value === nothing || fix(var, internal_fix_value[(; ind..., _strict=false)])
    var
end


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
    t_lowest_resolution_path(m, indices...)

An iterator of tuples `(t, path)` where `t` is a `TimeSlice` and `path` is a `Vector` of stochastic scenario `Object`s
corresponding to the active stochastic paths for that `t`.
The `t`s in the result are the lowest resolution `TimeSlice`s in `indices`.
For each of these `t`s, the `path` also includes scenarios in `more_indices` where the `TimeSlice` contains the `t`.
"""
function t_lowest_resolution_path(m, indices, more_indices...)
    isempty(indices) && return ()
    scens_by_t = t_lowest_resolution_sets!(_scens_by_t(indices))
    for (other_t, other_scens) in _scens_by_t(Iterators.flatten(more_indices))
        for (t, scens) in scens_by_t
            if iscontained(t, other_t)
                union!(scens, other_scens)
            end
        end
    end
    ((t, path) for (t, scens) in scens_by_t for path in active_stochastic_paths(m, scens))
end

function _scens_by_t(indices)
    scens_by_t = Dict()
    for x in indices
        scens = get!(scens_by_t, x.t) do
            Set{Object}()
        end
        push!(scens, x.stochastic_scenario)
    end
    scens_by_t
end

function past_units_on_indices(m, u, s, t, min_time)
    t0 = _analysis_time(m)
    units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - min_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t))
        ),
        temporal_block=anything
    )    
end

function _minimum_operating_point(u, ng, d, s, t0, t)
    minimum_operating_point[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=0)]
end

function _unit_flow_capacity(u, ng, d, s, t0, t)
    (
        + unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
        * unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
        * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
    )
end

function _start_up_limit(u, ng, d, s, t0, t)
    start_up_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function _shut_down_limit(u, ng, d, s, t0, t)
    shut_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

"""
    _switch(d; from_node, to_node)

Either `from_node` or `to_node` depending on the given direction `d`.

# Example

```julia
@assert _switch(direction(:from_node); from_node=3, to_node=-1) == 3
@assert _switch(direction(:to_node); from_node=3, to_node=-1) == -1
```
"""
function _switch(d; from_node, to_node)
    Dict(:from_node => from_node, :to_node => to_node)[d.name]
end

_overlapping_t(m, time_slices...) = [overlapping_t for t in time_slices for overlapping_t in t_overlaps_t(m; t=t)]

function _check_ptdf_duration(m, t, conns...)
    durations = [ptdf_duration(connection=conn, _default=nothing) for conn in conns]
    filter!(!isnothing, durations)
    isempty(durations) && return true
    duration = minimum(durations)
    elapsed = end_(t) - start(current_window(m))
    Dates.toms(duration - elapsed) >= 0
end

#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    add_constraint_unit_lifetime!(m::Model)

Constrain units_invested_available by the investment lifetime of a unit.
"""
function add_constraint_unit_lifetime!(m::Model)
    @fetch units_invested_available, units_invested = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_lifetime] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            expr_sum(
                units_invested_available[u, s, t]
                for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            sum(
                units_invested[u, s_past, t_past]
                for (u, s_past, t_past) in _past_units_invested_available_indices(m, u, s, t)
            )
        )
        for (u, s, t) in constraint_unit_lifetime_indices(m)
    )
end

function constraint_unit_lifetime_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        for (u, t) in unit_investment_time_indices(m; unit=u)
        for path in active_stochastic_paths(m, _past_units_invested_available_indices(m, u, anything, t))
    )
end

function _past_units_invested_available_indices(m, u, s, t)
    t0 = _analysis_time(m)
    units_invested_available_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m;
            t=TimeSlice(
                end_(t) - unit_investment_lifetime(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t)
            )
        )
    )
end

"""
    constraint_unit_lifetime_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_lifetime()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_unit_lifetime_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_lifetime_indices(m))
end


#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    nonspin_units_shut_down_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `nonspin_units_shut_down` variable
where the keyword arguments act as filters for each dimension.
"""
function nonspin_units_shut_down_indices(
    m::Model;
    unit=anything,
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unique(
        (unit=u, node=n, stochastic_scenario=s, t=t)
        for (u, n, d, s, t) in unit_flow_indices(
            m; unit=unit, node=node, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block
        )
        if is_reserve_node(node=n) && is_non_spinning(node=n)
    )
end

"""
    add_variable_nonspin_units_shut_down!(m::Model)

Add `nonspin_units_shut_down` variables to model `m`.
"""
function add_variable_nonspin_units_shut_down!(m::Model)
    t0 = start(current_window(m))
    add_variable!(
        m,
        :nonspin_units_shut_down,
        nonspin_units_shut_down_indices;
        lb=Constant(0),
        bin=units_on_bin,
        int=units_on_int,
        fix_value=fix_nonspin_units_shut_down,
        initial_value=initial_nonspin_units_shut_down
    )
end

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
    @log(level, threshold, msg)
"""
macro log(level, threshold, msg)
    quote
        if $(esc(level)) >= $(esc(threshold))
            printstyled($(esc(msg)), "\n"; bold=true)
            yield()
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
        r = @time $(esc(expr))
        yield()
        r
    end
end

"""
    @fetch x, y, ... = d

Assign mapping of :x and :y in `d` to `x` and `y` respectively
"""
macro fetch(expr)
    (expr isa Expr && expr.head == :(=)) || error("please use @fetch with the assignment operator (=)")
    keys, dict = expr.args
    values = if keys isa Expr
        Expr(:tuple, [:($dict[$(Expr(:quote, k))]) for k in keys.args]...)
    else
        :($dict[$(Expr(:quote, keys))])
    end
    esc(Expr(:(=), keys, values))
end

# override `get` and `getindex` so we can access our variable dicts with a `Tuple` instead of the actual `NamedTuple`
function Base.get(d::Dict{K,V}, key::Tuple{Vararg{ObjectLike}}, default) where {J,K<:RelationshipLike{J},V}
    Base.get(d, NamedTuple{J}(key), default)
end

function Base.getindex(d::Dict{K,V}, key::ObjectLike...) where {J,K<:RelationshipLike{J},V}
    Base.getindex(d, NamedTuple{J}(key))
end

_ObjectArrayLike = Union{ObjectLike,Array{T,1} where T<:ObjectLike}
_RelationshipArrayLike{K} = NamedTuple{K,V} where {K,V<:Tuple{Vararg{_ObjectArrayLike}}}

function Base.getindex(d::Dict{K,V}, key::_ObjectArrayLike...) where {J,K<:_RelationshipArrayLike{J},V}
    Base.getindex(d, NamedTuple{J}(key))
end

"""
    sense_constraint(m, lhs, sense::Symbol, rhs)

Create a JuMP constraint with the desired left-hand-side `lhs`, `sense`, and right-hand-side `rhs`.
"""
function sense_constraint(m, lhs, sense::Symbol, rhs)
    if sense == :>=
        @constraint(m, lhs >= rhs)
    elseif sense == :<=
        @constraint(m, lhs <= rhs)
    else
        @constraint(m, lhs == rhs)
    end
end
sense_constraint(m, lhs, sense::typeof(<=), rhs) = @constraint(m, lhs <= rhs)
sense_constraint(m, lhs, sense::typeof(==), rhs) = @constraint(m, lhs == rhs)
sense_constraint(m, lhs, sense::typeof(>=), rhs) = @constraint(m, lhs >= rhs)

"""
    expr_sum(iter; init::Number)

Sum elements in iter to init in-place, and return the result as a GenericAffExpr.
"""
function expr_sum(iter; init::Number)
    result = AffExpr(init)
    isempty(iter) && return result
    result += first(iter)  # NOTE: This is so result has the right type, e.g., `GenericAffExpr{Call,VariableRef}`
    for item in Iterators.drop(iter, 1)
        add_to_expression!(result, item)
    end
    result
end

function expr_avg(iter; init::Number)
    result = AffExpr(init)
    isempty(iter) && return result
    result += first(iter)  # NOTE: This is so result has the right type, e.g., `GenericAffExpr{Call,VariableRef}`
    k = 1
    for item in Iterators.drop(iter, 1)
        add_to_expression!(result, item)
        k += 1
    end
    result / k
end


"""
    _index_in(ind::NamedTuple; kwargs...)

Whether or not each field in the given named tuple is in sets passed as keyword arguments.
Used in constraint indices filtered functions.

# Examples

ind = (connection=1, unit=2)
_index_in(ind; connection=[1, 2, 3]) # true
_index_in(ind; unit=[3, 4]) # false
_index_in(ind; node=[8]) # raises ERROR: NamedTuple has no field node
"""
function _index_in(ind::NamedTuple; kwargs...)
    for (key, value) in pairs(kwargs)
        ind[key] == value || ind[key] in value || return false
    end
    true
end

"""
An iterator over the `TimeSlice` keys in `ind`
"""
_time_slice_keys(ind::NamedTuple) = (k for (k, v) in pairs(ind) if v isa TimeSlice)

"""
Drop keys from a `NamedTuple`.
"""
_drop_key(x::NamedTuple, key::Symbol...) = (; (k => v for (k, v) in pairs(x) if !(k in key))...)

"""
    _analysis_time(m::Model)

Fetch the current analysis time for the model `m`.
"""
_analysis_time(m::Model) = startref(current_window(m))

function get_module(module_name)
    for parent_module in (Base.Main, @__MODULE__)
        try
            return getproperty(parent_module, module_name)
        catch
        end
    end
end

struct Constant
    value
end

Base.getindex(c::Constant, _x) = Call(c.value)

name_from_fn(fn) = split(split(string(fn), "add_")[2], "!")[1]

function print_model_and_solution(m, variable_patterns...)
    println(m)
    print_solution(m, variable_patterns...)
end

function print_solution(m, variable_patterns...)
    println("Results")
    println("objective value = ", objective_value(m))
    for v in all_variables(m)
        isempty(variable_patterns) || all(occursin(pattern, name(v)) for pattern in variable_patterns) || continue
        println(v, " = ", value(v))
    end
    println()
end

function window_sum_duration(m, ts::TimeSeries, window; init=0)
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    time_slice_value_iter = (
        (TimeSlice(t1, t2; duration_unit=dur_unit), v) for (t1, t2, v) in zip(ts.indexes, ts.indexes[2:end], ts.values)
    )
    sum(v * duration(t) for (t, v) in time_slice_value_iter if iscontained(start(t), window) && !isnan(v); init=init)
end
window_sum_duration(m, x::Number, window; init=0) = x * duration(window) + init

window_sum(ts::TimeSeries, window; init=0) = sum(v for (t, v) in ts if iscontained(t, window) && !isnan(v); init=init)
window_sum(x::Number, window; init=0) = x + init


"""
    align_variable_duration_unit(_duration::Union{Period, Nothing}, dt::DateTime; ahead::Bool=true)

Aligns a duration of the type `Month` or `Year` to `Day` counting from a `DateTime` input `dt`.

# Arguments
- _duration: an integeral duration of the abstract type `Period` defined in Dates.jl,
             e.g. `Hour`, `Day`, `Month` that can be obtained by `Dates.Hour(2)` and so forth.
             It can also catch any duration-like parameter of Spine, including `Nothing`. 
- dt: a DateTime object as the reference.
- ahead=true: a boolean value indicating whether the duration counts ahead of or behind the reference point.

# Returns
- a new positive duration of the type `Day` that is comparable with constant duration types such as `Hour`.

# Examples
```julia
    
_duration1 = Month(1); _duration2 = Day(32)
dt1 = DateTime(2024, 2, 1); dt2 = DateTime(2024, 4, 1)

new_duration1 = align_variable_duration_unit(_duration1, dt1)
new_duration2 = align_variable_duration_unit(_duration1, dt2)
new_duration3 = align_variable_duration_unit(_duration1, dt1; ahead=false)
new_duration4 = align_variable_duration_unit(_duration2, dt1)
    
```
--> new_duration1: 29 days; new_duration1 == Day(29): true
--> new_duration2: 30 days
--> new_duration3: 31 days
--> new_duration4: 32 days

This convertion is needed for comparing a duration of the type `Month` or `Year` with 
one of `Day`, `Hour` or the finer units, which is not allowed because the former are variable duration types.
"""
function align_variable_duration_unit(_duration::Union{Period, Nothing}, dt::DateTime; ahead=true)
    #TODO: the value of `_duration` is assumed to be an integer. A warning should be given.
    #TODO: new format to record durations would be benefitial, e.g. 3M2d1h,
    #      cf. Dates.CompoundPeriod in the periods.jl of Julia standard library.
    if _duration isa Month || _duration isa Year
        ahead ? Day((dt + _duration) - dt) : Day(dt - (dt - _duration))
    else
        _duration
    end
end
