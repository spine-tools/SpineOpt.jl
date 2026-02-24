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
        @timelog $(esc(level)) $(esc(threshold)) $(esc(msg)) nothing $(esc(expr))
    end
end
macro timelog(level, threshold, msg, stats, expr)
    quote
        if $(esc(level)) >= $(esc(threshold))
            @timemsg $(esc(msg)) $(esc(stats)) $(esc(expr))
        else
            $(esc(expr))
        end
    end
end

macro timemsg(msg, stats, expr)
    :(timemsg($(esc(msg)), $(esc(stats)), () -> $(esc(expr))))
end

function timemsg(msg, stats, f)
    printstyled(stdout, msg; bold=true)
    if stats isa Dict
        result = @timed @time f()
        push!(get!(stats, strip(msg), []), result.time)
        result.value
    else
        @time f()
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

"""
    @generator function(foo)
        for x in 1:10
            @yield x
        end
    end

Create a Python-style generator from the given function that calls the @yield macro.
"""
macro generator(f)
    if f.head != :function
        error("please use @generator with a function")
    end
    signature, body = f.args
    name, args... = signature.args
    channel = gensym()
    _expand_yield_macro!(body, channel)
    producer = gensym()
    producer_fn = quote
        function $(producer)($channel)
            $(body)
        end
    end
    quote
        function $(esc(name))($(esc.(args)...))  # TODO: Support keyword arguments
            $(esc(producer_fn))
            Channel($(esc(producer)))
        end
    end
end

macro yield(x)
    x
end

function _expand_yield_macro!(expr::Expr, channel)
    for (k, x) in enumerate(expr.args)
        x isa Expr || continue
        if x.head == :macrocall && x.args[1] == Symbol("@yield")
            # TODO: make sure @yield is called correctly by checking x.args[2:end]
            value = x.args[end]
            expr.args[k] = quote
                put!($channel, $value)
            end
        else
            _expand_yield_macro!(x, channel)
        end
    end
end

struct ParameterFunction
    fn
end

(pf::ParameterFunction)(; kwargs...) = as_number(pf; kwargs...)

as_number(p::Parameter; kwargs...) = p(; kwargs...)
as_number(pf::ParameterFunction; kwargs...) = pf.fn(as_number; kwargs...)

as_call(p::Parameter; kwargs...) = p[kwargs]
as_call(pf::ParameterFunction; kwargs...) = pf.fn(as_call; kwargs...)

constant(x::Number) = (m; kwargs...) -> x

"""
    build_sense_constraint(lhs, sense::Symbol, rhs)

A JuMP constraint with the desired left-hand-side `lhs`, `sense`, and right-hand-side `rhs`.
"""
build_sense_constraint(lhs, sense::Symbol, rhs) = build_sense_constraint(lhs, getproperty(Base, sense), rhs)
build_sense_constraint(lhs, sense::typeof(<=), rhs) = @build_constraint(lhs <= rhs)
build_sense_constraint(lhs, sense::typeof(==), rhs) = @build_constraint(lhs == rhs)
build_sense_constraint(lhs, sense::typeof(>=), rhs) = @build_constraint(lhs >= rhs)

function _avg(iter; init::Number)
    iter = collect(iter)
    isempty(iter) ? init : sum(iter; init=init) / length(iter)
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
function align_variable_duration_unit(duration::Union{Period, Nothing}, dt::DateTime; ahead=true)
    #TODO: the value of `duration` is assumed to be an integer. A warning should be given.
    #TODO: new format to record durations would be benefitial, e.g. 3M2d1h,
    #      cf. Dates.CompoundPeriod in the periods.jl of Julia standard library.
    if duration isa Month || duration isa Year
        ahead ? Day((dt + duration) - dt) : Day(dt - (dt - duration))
    else
        duration
    end
end

function _log_to_file(fn, log_file_path)
    log_file_path === nothing && return fn()
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
                    fn()
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

function _call_event_handlers(m, event, args...; kwargs...)
    (fn -> fn(m, args...; kwargs...)).(m.ext[:spineopt].event_handlers[event])
end

function _pkgversion(pkg)
    isdefined(Base, :pkgversion) && return pkgversion(pkg)
    project_filepath = joinpath(pkgdir(pkg), "Project.toml")
    parsed_contents = TOML.parsefile(project_filepath)
    parsed_contents["version"]
end

function _version_and_git_hash(pkg)
    version = string(_pkgversion(pkg))
    git_hash = try
        repo = LibGit2.GitRepo(pkgdir(pkg))
        string(LibGit2.head_oid(repo))
    catch err
        err isa LibGit2.GitError || rethrow()
        "N/A"
    end
    version, git_hash
end

"""
    _similar(node1, node2)

A Boolean indicating whether or not two nodes are 'similar', in the sense they are single nodes
(i.e. not groups) with the same temporal and stochastic structure.
"""
function _similar(node1, node2)
    (
        members(node1) == [node1]
        && members(node2) == [node2]
        && node__temporal_block(node=node1) == node__temporal_block(node=node2)
        && node__stochastic_structure(node=node1) == node__stochastic_structure(node=node2)
    )
end

"""
    _related_flows(fix_ratio_d1_d2)

Take an iterator over tuples `(fix_ratio, direction1, direction2)` and return another iterator over tuples
`(unit or connection, ref_node, ref_direction, node, direction, fix_ratio, direct)`,
corresponding to a reference flow and a flow that can be expressed in terms of it via a fix ratio.
`direct` is `true` if `(direction, ref_direction) == (direction1, direction2)` and `false` otherwise.
The result guarantees that no flows refer to each other, that the number of reference flows is minimal,
and that if a reference flow can also be expressed in terms of another reference flow,
then the reference's reference is always issued first.
"""
function _related_flows(fix_ratio_d1_d2)
    flows_by_ref_flow = OrderedDict()
    fix_ratio_direct = Dict()
    for (fix_ratio, d1, d2) in fix_ratio_d1_d2
        for (x, n1, n2) in indices(fix_ratio)
            _similar(n1, n2) || continue
            f1 = (x, n1, d1)
            f2 = (x, n2, d2)
            push!(get!(flows_by_ref_flow, f2, Set()), f1)
            push!(get!(flows_by_ref_flow, f1, Set()), f2)
            fix_ratio_direct[x, n2, d2, n1, d1] = (fix_ratio, true)
            fix_ratio_direct[x, n1, d1, n2, d2] = (fix_ratio, false)
        end
    end
    sort!(flows_by_ref_flow; by=(k -> length(flows_by_ref_flow[k])), rev=true)
    seen_flows = Set()
    for (ref, flows) in flows_by_ref_flow
        setdiff!(flows, seen_flows)
        push!(seen_flows, ref)
        union!(seen_flows, flows)
    end
    lt(flow1, flow2) = flow2 in get(flows_by_ref_flow, flow1, ())
    sort!(flows_by_ref_flow; lt=lt)
    (
        (x, n_ref, d_ref, n, d, fix_ratio_direct[x, n_ref, d_ref, n, d]...)
        for ((x, n_ref, d_ref), flows) in flows_by_ref_flow
        for (_x, n, d) in flows
    )
end

_div_or_zero(x, y) = iszero(y) ? zero(y) : x / y

_make_bi(j) = Object(Symbol(:bi_, lpad(j, 3, "0")), :benders_iteration)

"""
    _get_max_duration(m::Model, lookback_params::Vector{Parameter})

The maximum duration from a list of parameters.
"""
function _get_max_duration(m::Model, lookback_params::Vector{Parameter})
    max_vals = (maximum_parameter_value(p) for p in lookback_params)
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    reduce(max, (val for val in max_vals if val !== nothing); init=dur_unit(1))
end

_force_fix(v::VariableRef, x) = fix(v, x; force=true)
_force_fix(::Call, x) = nothing

_percentage_str(x::Number) = string(@sprintf("%1.4f", x * 100), "%")

_number_str(x::Number) = @sprintf("%.5e", x)

function _with_model_env(f, m)
    st = m.ext[:spineopt].stage
    scen = stage_scenario(stage=st, _strict=false)
    scen === nothing && return f()
    with_env(scen) do
        f()
    end
end

function _elapsed_time_string(t_start, t_end)
    string(Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(t_end - t_start))))
end

# Base
_ObjectArrayLike = Union{ObjectLike,Array{T,1} where T<:ObjectLike}
_RelationshipArrayLike{K} = NamedTuple{K,V} where {K,V<:Tuple{Vararg{_ObjectArrayLike}}}

function Base.get(d::Dict{K,V}, key::Tuple{Vararg{ObjectLike}}, default) where {J,K<:RelationshipLike{J},V}
    Base.get(d, NamedTuple{J}(key), default)
end
function Base.get(f::Function, d::Dict{K,V}, key::Tuple{Vararg{ObjectLike}}) where {J,K<:RelationshipLike{J},V}
    Base.get(f, d, NamedTuple{J}(key))
end

function Base.haskey(d::Dict{K,V}, key::Tuple{Vararg{ObjectLike}}) where {J,K<:RelationshipLike{J},V}
    Base.haskey(d, NamedTuple{J}(key))
end

function Base.getindex(d::Dict{K,V}, key::ObjectLike...) where {J,K<:RelationshipLike{J},V}
    getindex(d, NamedTuple{J}(key))
end
function Base.getindex(d::Dict{K,V}, key::_ObjectArrayLike...) where {J,K<:_RelationshipArrayLike{J},V}
    Base.getindex(d, NamedTuple{J}(key))
end
