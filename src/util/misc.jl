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
