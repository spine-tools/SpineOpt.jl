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