#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
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


function Base.getindex(d::Dict{NamedTuple{X,Y},Z}, key::ObjectLike...) where {N,Y<:NTuple{N,ObjectLike},X,Z}
    isempty(d) && throw(KeyError(key))
    names = keys(first(keys(d))) # Get names from first key, TODO: check how bad this is for performance
    Base.getindex(d, NamedTuple{names}(values(key)))
end

"""
    pack_trailing_dims(dictionary::Dict, n::Int64=1)

An equivalent dictionary where the last `n` dimensions are packed into a matrix
"""
function pack_trailing_dims(dictionary::Dict{S,T}, n::Int64=1) where {S<:NamedTuple,T}
    left_dict = Dict{Any,Any}()
    for (key, value) in dictionary
        # TODO: handle length(key) < n and stuff like that?
        left_key = NamedTuple{Tuple(collect(keys(key))[1:end-n])}(collect(values(key))[1:end-n])
        right_key = NamedTuple{Tuple(collect(keys(key))[end-n+1:end])}(collect(values(key))[end-n+1:end])
        right_dict = get!(left_dict, left_key, Dict())
        right_dict[right_key] = value
    end
    if n > 1
        Dict(key => reshape([v for (k, v) in sort(collect(value))], n, :) for (key, value) in left_dict)
    else
        Dict(key => [v for (k, v) in sort(collect(value))] for (key, value) in left_dict)
    end
end


pack_time_series(dictionary::Dict) = dictionary

"""
    pack_time_series(dictionary::Dict)

An equivalent dictionary where the last dimension is packed into a time series
(i.e., a `Dict` mapping `String` time stamps to data).
"""
function pack_time_series(dictionary::Dict{NamedTuple{X,Y},Z}) where {N,Y<:NTuple{N,ObjectLike},X,Z}
    if Y.parameters[N] != TimeSlice
        @warn("can't pack objects of type `$(Y.parameters[N])` into a time series")
        return dictionary
    end
    left_dict = Dict{Any,Any}()
    for (key, value) in dictionary
        key_keys = collect(keys(key))
        key_values = collect(values(key))
        left_key = NamedTuple{Tuple(key_keys[1:end-1])}(key_values[1:end-1])
        right_dict = get!(left_dict, left_key, Dict{String,Any}())
        # NOTE: The time stamp is the start point of the `TimeSlice`
        right_key = Dates.format(start(key[end]), iso8601zoneless)
        right_dict[right_key] = value
    end
    Dict(key => sort(value) for (key, value) in left_dict)
end

"""
    value(d::Dict)

An equivalent dictionary where `JuMP.VariableRef` values are replaced by their `JuMP.value`.
"""
value(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => JuMP.value(v) for (k, v) in d if v isa JuMP.VariableRef)

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by a `String` showing their formulation.
"""
formulation(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d if v isa JuMP.ConstraintRef)

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


macro catch_undef(expr)
    (expr isa Expr && expr.head == :function) || error("please use @catch_undef with function definitions")
    name = expr.args[1].args[1]
    body = expr.args[2]
    new_expr = copy(expr)
    new_expr.args[2] = quote
        try
            $body
        catch e
            !(e isa UndefVarError) && rethrow()
            @warn("$(e.var) not defined, skipping $($name)")
        end
    end
    esc(new_expr)
end



expand_unit_group(::Anything) = anything
expand_node_group(::Anything) = anything
expand_commodity_group(::Anything) = anything

function expand_unit_group(ugs::X) where X >: Anything
    [u for ug in ugs for u in unit_group__unit(unit1=ug, _default=ug)]
end

function expand_node_group(ngs::X) where X >: Anything
    [n for ng in ngs for n in node_group__node(node1=ng, _default=ng)]
end

function expand_commodity_group(cgs::X) where X >: Anything
    [c for cg in cgs for c in commodity_group__commodity(commodity1=cg, _default=cg)]
end
