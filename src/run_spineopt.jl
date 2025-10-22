#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
The argument `url_in` must be either a `String` pointing to a valid Spine database,
or a `Dict` (e.g. manually created or parsed from a json file).
A new Spine database is created at `url_out` if one doesn't exist.

# Arguments

- `log_level::Int=3`: an integer to control the log level.
- `upgrade::Bool=false`: whether or not to automatically upgrade the data structure in `url_in` to latest.
- `filters::Dict{String,String}=Dict("tool" => "object_activity_control")`: a dictionary to specify filters.
   Possible keys are "tool" and "scenario". Values should be a tool or scenario name in the input DB.
- `templates`: a collection of templates to load on top of the SpineOpt template.
   Each template must be a `Dict` with the same structure as the one returned by `SpineOpt.template()`.
- `mip_solver=nothing`: a MIP solver to use if no MIP solver specified in the DB.
- `lp_solver=nothing`: a LP solver to use if no LP solver specified in the DB.
- `use_direct_model::Bool=false`: whether or not to use `JuMP.direct_model` to build the `Model` object.
- `use_model_names::Bool=true`: whether or not to use the names in the model.
- `add_bridges::Bool=true` whether or not bridges from JuMP to the solver should be added to the model.
- `optimize::Bool=true`: whether or not to optimise the model (useful for running tests).
- `update_names::Bool=false`: whether or not to update variable and constraint names after the model rolls
   (expensive).
- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.
- `write_as_roll::Int=0`: if greater than 0 and the run has a rolling horizon, then write results every that many
   windows.
- `log_file_path::String=nothing`: if not nothing, log all console output to a file at the given path. The file
   is overwritten at each call.
- `resume_file_path::String=nothing`: only relevant in rolling horizon optimisations with `write_as_roll` greater or
   equal than one. If the file at given path contains resume data from a previous run, start the run from that point.
   Also, save resume data to that same file as the model rolls and results are written to the output database.

# Example

```julia
using SpineOpt
m = run_spineopt(
    raw"sqlite:///C:\\path\\to\\your\\input_db.sqlite", 
    raw"sqlite:///C:\\path\\to\\your\\output_db.sqlite";
    filters=Dict("tool" => "object_activity_control", "scenario" => "scenario_to_run"),
    alternative="alternative_to_write_results"
)
```
"""
function run_spineopt(url_in::Union{String,Dict}, url_out::Union{String,Nothing}=url_in; kwargs...)
    run_spineopt(m -> nothing, url_in, url_out; kwargs...)
end
"""
    run_spineopt(f, url_in, url_out; <keyword arguments>)

Same as `run_spineopt(url_in, url_out; kwargs...)` but call function `f` with the SpineOpt model as argument
right after its creation (but before building and solving it).

This is intended to be called using do block syntax.

```julia
run_spineopt(url_in, url_out) do m
    # Do something with m after its creation
end  # Building and solving begins after quiting this block
```
"""
function run_spineopt(
    f::Function,
    url_in::Union{String,Dict},
    url_out::Union{String,Nothing}=url_in;
    log_level=3,
    upgrade=false,
    filters=Dict("tool" => "object_activity_control"),
    templates=(),
    mip_solver=nothing,
    lp_solver=nothing,
    use_direct_model=false,
    use_model_names=true,
    add_bridges=true,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    log_file_path=nothing,
    resume_file_path=nothing,
)
    _log_to_file(log_file_path) do
        _run_spineopt(
            f,
            url_in,
            url_out;
            log_level=log_level,
            upgrade=upgrade,
            filters=filters,
            templates=templates,
            mip_solver=mip_solver,
            lp_solver=lp_solver,
            use_direct_model=use_direct_model,
            use_model_names=use_model_names,
            add_bridges=add_bridges,
            optimize=optimize,
            update_names=update_names,
            alternative=alternative,
            write_as_roll=write_as_roll,
            resume_file_path=resume_file_path,
        )
    end
end

function _run_spineopt(
    f,
    url_in,
    url_out;
    upgrade,
    filters,
    templates,
    mip_solver,
    lp_solver,
    use_direct_model,
    use_model_names,
    add_bridges,
    log_level,
    alternative,
    kwargs...,
)
    @log log_level 0 "\nRunning SpineOpt..."
    so_ver, so_git_hash = _version_and_git_hash(SpineOpt)
    si_ver, si_git_hash = _version_and_git_hash(SpineInterface)    
    println("[SpineOpt version $so_ver (git hash: $so_git_hash)]")
    println("[SpineInterface version $si_ver (git hash: $si_git_hash)]")
    t_start = now()
    @log log_level 1 "Execution started at $t_start"
    m = prepare_spineopt(
            url_in;
            upgrade,
            filters,
            templates,
            mip_solver,
            lp_solver,
            use_direct_model,
            use_model_names,
            add_bridges,
            log_level,
        )
    f(m)
    run_spineopt!(m, url_out; log_level, alternative, kwargs...)
    t_end = now()
    elapsed_time_string = _elapsed_time_string(t_start, t_end)
    @log log_level 1 "Execution complete. Started at $t_start, ended at $t_end, elapsed time: $elapsed_time_string"
    if url_out !== nothing
        stat_keys = [
            :SpineOpt_version, :SpineOpt_git_hash, :SpineInterface_version, :SpineInterface_git_hash, :elapsed_time
        ]
        stat_values = Any[so_ver, so_git_hash, si_ver, si_git_hash, elapsed_time_string]
        models = [m]
        if master_model(m) !== nothing
            push!(models, master_model(m))
        end
        append!(models, values(m.ext[:spineopt].model_by_stage))
        for key in (:build_time, :solve_time)
            time = merge((get(m.ext[:spineopt].extras, key, Dict()) for m in models)...)
            if !isempty(time)
                time_map = Map(string.(keys(time)), collect(values(time)))
                push!(stat_keys, key)
                push!(stat_values, time_map)
            end
        end
        if master_model(m) !== nothing
            m_mp = master_model(m)
            gaps = m_mp.ext[:spineopt].benders_gaps
            if !isempty(gaps)
                append!(
                    stat_keys,
                    [
                        :benders_objective_lower_bound,
                        :benders_objective_upper_bound,
                        :benders_gap,
                        :benders_iteration_count,
                    ],
                )
                benders_stat_values = if report_benders_iterations(model=m.ext[:spineopt].instance, _default=false)
                    lbs = m_mp.ext[:spineopt].objective_lower_bounds
                    ubs = m_mp.ext[:spineopt].objective_upper_bounds
                    [lbs, ubs, gaps, length(gaps)]
                else
                    [_lb_str(m_mp), _ub_str(m_mp), _gap_str(m_mp), length(gaps)]
                end
                append!(stat_values, benders_stat_values)
            end
        end
        stats = Map(stat_keys, stat_values)
        vals = Dict(:solution_stats => Dict((model=m.ext[:spineopt].instance,) => stats))
        write_parameters(vals, url_out; alternative=alternative, on_conflict="replace")
    end
    m
    # FIXME: make sure use_direct_model this works with db solvers
    # possibly adapt union? + allow for conflicts if direct model is used
end

function _current_solution_string(m_mp)
    if isempty(m_mp.ext[:spineopt].benders_gaps)
        ""
    else
        "(lower bound: $(_lb_str(m_mp)); upper bound: $(_ub_str(m_mp)); gap: $(_gap_str(m_mp))) "
    end
end

_gap_str(m_mp) = _percentage_str(last(m_mp.ext[:spineopt].benders_gaps))

_lb_str(m_mp) = _number_str(last(m_mp.ext[:spineopt].objective_lower_bounds))

_ub_str(m_mp) = _number_str(last(m_mp.ext[:spineopt].objective_upper_bounds))

"""
    prepare_spineopt(url_in; <keyword arguments>)

A SpineOpt model from the contents of `url_in` - ready to be passed to [run_spineopt!](@ref).
The argument `url_in` must be either a `String` pointing to a valid Spine database,
or a `Dict` (e.g. manually created or parsed from a json file).

# Arguments

- `log_level`
- `upgrade`
- `filters`
- `templates`
- `mip_solver`
- `lp_solver`
- `use_direct_model`
- `use_model_names`
- `add_bridges`

See [run_spineopt](@ref) for the description of the keyword arguments.
"""
function prepare_spineopt(
    url_in;
    log_level=3,
    upgrade=false,
    filters=Dict("tool" => "object_activity_control"),
    templates=(),
    mip_solver=nothing,
    lp_solver=nothing,
    use_direct_model=false,
    use_model_names=true,
    add_bridges=true,
)
    @log log_level 0 "Reading input data from $(_real_url(url_in))..."
    _check_version(url_in; log_level, upgrade)
    template, data = _init_data_from_db(url_in, log_level, upgrade, templates, filters)
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
    scenarios = []
    for st in stage()
        scenario = stage_scenario(stage=st, _strict=false)
        scenario isa Symbol || error("invalid scenario $scenario for stage $st")
        push!(scenarios, scenario)
    end
    for scenario in scenarios
        without_filters(url_in) do clean_url_in
            filters = merge(filters, Dict("scenario" => string(scenario)))
            with_env(scenario) do
                _init_data_from_db(clean_url_in, log_level, upgrade, templates, filters, scenario)
            end
        end
    end
    _set_value_translator()
    create_model(mip_solver, lp_solver, use_direct_model, use_model_names, add_bridges)
end

function _init_data_from_db(url_in, log_level, upgrade, templates, filters, scenario="")
    @timelog log_level 2 "Initializing $scenario data structure from db..." begin
        template = SpineOpt.template()
        using_spinedb(template, @__MODULE__; extend=false)
        for template in templates
            using_spinedb(template, @__MODULE__; extend=true)
        end
        data = _data(url_in; upgrade, filters)
        using_spinedb(data, @__MODULE__; extend=true)
    end
    @timelog log_level 2 "Preprocessing $scenario data structure..." preprocess_data_structure()
    @timelog log_level 2 "Checking $scenario data structure..." check_data_structure()
    template, data
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

_data(url_in; upgrade, filters) = export_data(url_in; upgrade=upgrade, filters=filters)
_data(data::Dict; kwargs...) = data

"""
    run_spineopt!(m, url_out; <keyword arguments>)

Build SpineOpt on the given `m` and solve it; write report(s) to `url_out`.
A new Spine database is created at `url_out` if one doesn't exist.

# Arguments

- `log_level`
- `optimize`
- `update_names`
- `alternative`
- `write_as_roll`
- `log_file_path`
- `resume_file_path`

See [run_spineopt](@ref) for the description of the keyword arguments.
"""
function run_spineopt!(
    m::Model,
    url_out::Union{String,Nothing};
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    resume_file_path=nothing,
)
    # NOTE: invokelatest ensures that solver modules are available to use by JuMP
    Base.invokelatest(        
        do_run_spineopt!,
        m,
        url_out,
        Val(model_algorithm(model=m.ext[:spineopt].instance));
        log_level=log_level,
        optimize=optimize,
        update_names=update_names,
        alternative=alternative,
        write_as_roll=write_as_roll,
        resume_file_path=resume_file_path,
    )
end

"""
    create_model(mip_solver, lp_solver, use_direct_model, use_model_names, add_bridges)

A `JuMP.Model` extended to be used with SpineOpt.
`mip_solver` and `lp_solver` are 'optimizer factories' to be passed to `JuMP.Model` or `JuMP.direct_model`;
`use_direct_model` is a `Bool` indicating whether `JuMP.Model` or `JuMP.direct_model` should be used.
`use_model_names` is a `Bool` indicating whether the names in the model should be used.
`add_bridges` is a `Bool` indicating whether bridges from JuMP to the solver should be added to the model.
"""
function create_model(mip_solver, lp_solver, use_direct_model, use_model_names, add_bridges)
    instance = first(model())
    mip_solver = _mip_solver(instance, mip_solver)
    lp_solver = _lp_solver(instance, lp_solver)
    algorithm = model_algorithm(model=instance)
    if needs_bridges(Val(algorithm)) && !add_bridges
        add_bridges = true
        @warn "Bridges are required for $algorithm algorithm - adding them"
    end
    m_mp = if model_type(model=instance) === :spineopt_benders
        m_mp = Base.invokelatest(_do_create_model, mip_solver, use_direct_model, add_bridges)
        m_mp.ext[:spineopt] = SpineOptExt(instance, lp_solver, m_mp)
        JuMP.set_string_names_on_creation(m_mp, use_model_names)
        m_mp
    end
    model_by_stage = OrderedDict()
    for st in sort(stage(); lt=(x, y) -> y in stage__child_stage(stage1=x))
        model_by_stage[st] = stage_m = Base.invokelatest(_do_create_model, mip_solver, use_direct_model, add_bridges)
        stage_m.ext[:spineopt] = SpineOptExt(instance, lp_solver, m_mp; stage=st)
    end
    m = Base.invokelatest(_do_create_model, mip_solver, use_direct_model, add_bridges)
    m.ext[:spineopt] = SpineOptExt(instance, lp_solver, m_mp; model_by_stage=model_by_stage)
    JuMP.set_string_names_on_creation(m, use_model_names)
    m
end

"Standard algorithms do not require optimizer bridges"
needs_bridges(model_algorithm) = false

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

function _do_create_model(mip_solver, use_direct_model, add_bridges)
    use_direct_model ? direct_model(mip_solver) : Model(mip_solver; add_bridges=add_bridges)
end

struct SpineOptExt
    instance::Object
    lp_solver
    master_model::Union{Model,Nothing}
    model_by_stage::OrderedDict{Object,Model}
    stage::Union{Object,Nothing}
    intermediate_results_folder::String
    reports_by_output::Dict
    variables::Dict{Symbol,Dict}
    variables_definition::Dict{Symbol,Dict}
    values::Dict{Symbol,Dict}
    results::Dict{Any,Dict}
    constraints::Dict{Symbol,Dict}
    expressions::Dict{Symbol,Dict}
    objective_terms::Dict{Symbol,Any}
    outputs::Dict{Symbol,Union{Dict,Nothing}}
    downstream_outputs::Dict{Symbol,Dict}
    temporal_structure::Dict
    stochastic_structure::Dict
    dual_solves::Array{Any,1}
    dual_solves_lock::ReentrantLock
    objective_lower_bounds::Vector{Float64}
    objective_upper_bounds::Vector{Float64}
    benders_gaps::Vector{Float64}
    has_results::Base.RefValue{Bool}
    event_handlers::Dict
    extras::Dict
    function SpineOptExt(instance, lp_solver, master_model=nothing; model_by_stage=Dict(), stage=nothing)
        intermediate_results_folder = if stage === nothing
            intermediate_results_folder = tempname(; cleanup=false)
            mkpath(intermediate_results_folder)
            intermediate_results_folder
        else
            ""
        end
        event_handlers = Dict(
            :model_built => Set(),
            :model_about_to_solve => Set(),
            :model_solved => Set(),
            :window_about_to_solve => Set(),
            :window_solved => Set(),
            :window_failed => Set(),
        )
        new(
            instance,
            lp_solver,
            master_model,
            model_by_stage,
            stage,
            intermediate_results_folder,
            Dict(),  # reports_by_output
            Dict{Symbol,Dict}(),  # variables
            Dict{Symbol,Dict}(),  # variables_definition
            Dict{Symbol,Dict}(),  # values
            Dict{Any,Dict}(),  # results
            Dict{Symbol,Dict}(),  # constraints
            Dict{Symbol,Dict}(),  # expressions
            Dict{Symbol,Any}(),  # objective_terms
            Dict{Symbol,Union{Dict,Nothing}}(),  # outputs
            Dict{Symbol,Dict}(),  # downstream_outputs
            Dict(),  # temporal_structure
            Dict(),  # stochastic_structure
            [],  # dual_solves
            ReentrantLock(),  # dual_solves_lock
            [],  # objective_lower_bounds
            [],  # objective_upper_bounds
            [],  # benders_gaps
            Ref(false),  # has_results
            event_handlers,
            Dict(),  # extras
        )
    end
end

function _model_name(m)
    st = m.ext[:spineopt].stage
    st !== nothing && return string(st.name, " stage")
    name = string(m.ext[:spineopt].instance.name)
    _is_benders_master(m) && return string(name, " master")
    name
end

_output_names(m::Model) = unique(first.(keys(m.ext[:spineopt].reports_by_output)))

JuMP.copy_extension_data(data::SpineOptExt, new_model::AbstractModel, model::AbstractModel) = nothing

"""
    master_model(m)

The Benders master model for given model.
"""
master_model(m) = m.ext[:spineopt].master_model

_is_benders_master(m) = master_model(m) === m

_is_benders_subproblem(m) = !(master_model(m) in (m, nothing))

"""
    stage_model(m, stage_name)

A stage model associated to given model.
"""
stage_model(m, stage_name::Symbol) = get(m.ext[:spineopt].model_by_stage, stage(stage_name), nothing)

"""
    upgrade_db(url_in; log_level=3)

Upgrade the data structure in `url_in` to latest.
"""
function upgrade_db(url_in; log_level=3)
    version = find_version(url_in)
    if version < current_version()
        _do_upgrade_db(url_in, version; log_level)
    end
end

"""
    add_event_handler!(fn, m, event)

Add an event handler for given model.
`event` must be a `Symbol` corresponding to an event.
`fn` must be a function callable with the arguments corresponding to that event.
Below is a table of events, arguments, and when do they fire.

| event | arguments | when does it fire |
| --- | --- | --- |
| `:model_built` | `m` | Right after model `m` is built. |
| `:model_about_to_solve` | `m` | Right before model `m` is solved. |
| `:model_solved` | `m` | Right after model `m` is solved. |
| `:window_about_to_solve` | `(m, k)` | Right before window `k` for model `m` is solved. |
| `:window_solved` | `(m, k)` | Right after window `k` for model `m` is solved. |
| `:window_failed` | `(m, k)` | Right after window `k` for model `m` fails to solve. |

# Example

```julia
run_spineopt("sqlite:///path-to-input-db", "sqlite:///path-to-output-db") do m
    add_event_handler!(println, m, :model_built)  # Print the model right after it's built
end
```
"""
function add_event_handler!(fn, m, event)
    event_handlers = m.ext[:spineopt].event_handlers
    listeners = get(event_handlers, event, nothing)
    listeners === nothing && error(
        "invalid event $event - must be one of $(join(keys(event_handlers), ", "))"
    )
    push!(listeners, fn)
end

function _save_result!(m, k=nothing; filter_accepts_variable=(x -> true))
    m.ext[:spineopt].results[k] = Dict(
        name => copy(m.ext[:spineopt].values[name])
        for name in keys(m.ext[:spineopt].variables)
        if filter_accepts_variable(name)
    )
end

function _set_result!(m, k=nothing)
    result = get(m.ext[:spineopt].results, k, nothing)
    result === nothing && return false
    for (name, variable_result) in result
        val = m.ext[:spineopt].values[name]
        for (ind, r) in variable_result
            val[ind] = r
        end
    end
    m.ext[:spineopt].has_results[] = true
end

function _set_starting_point!(m, k=nothing)
    for (name, variable_result) in get(m.ext[:spineopt].results, k, ())
        var_by_ind = m.ext[:spineopt].variables[name]
        var_def = m.ext[:spineopt].variables_definition[name]
        for (ind, r) in variable_result
            for new_ind in var_def[:indices](m; _drop_key(ind, :t)..., t=to_time_slice(m; t=ind.t))
                var = get(var_by_ind, new_ind, nothing)
                var isa VariableRef && set_start_value(var, r)
            end
        end
    end
end
