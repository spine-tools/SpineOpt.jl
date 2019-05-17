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

# const iso8601 = dateformat"yyyy-mm-ddTHH:MMz"
const iso8601zoneless = dateformat"yyyy-mm-ddTHH:MM"

function parse_date_time(value)
    DateTime(value, iso8601zoneless)
    # try
    #    ZonedDateTime(value, iso8601)
    # catch
    #    ZonedDateTime(DateTime(value, iso8601zoneless), tz"UTC")
    # end
end

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
        # Pick the `TimeSlice`'s start as time stamp
        right_key = Dates.format(start(key[end]), iso8601zoneless)
        right_dict[right_key] = value
    end
    Dict(key => sort(value) for (key, value) in left_dict)
end

pack_time_series(dictionary::Dict) = dictionary

"""
    value(d::Dict)

An equivalent dictionary where `JuMP.VariableRef` values are replaced by their `JuMP.value`.
"""
value(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => JuMP.value(v) for (k, v) in d if v isa JuMP.VariableRef)

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
            @warn("$(e.var) not defined, although needed by $($name) —anyways, moving on...")
        end
    end
    esc(new_expr)
end

"""
    parse_duration(str::String)

Parse the given string as a Period value.
"""
function parse_duration(str::String)
    split_str = split(str, " ")
    if length(split_str) == 1
        # Compact form, eg. "1D"
        number = str[1:end-1]
        time_unit = str[end]
        if lowercase(time_unit) == "y"
            Year(number)
        elseif time_unit == "m"
            Month(number)
        elseif time_unit == "d"
            Day(number)
        elseif time_unit == "H"
            Hour(number)
        elseif time_unit == "M"
            Minute(number)
        elseif time_unit == "S"
            Second(number)
        else
            error("invalid duration specification '$str'")
        end
    elseif length(split_str) == 2
        # Verbose form, eg. "1 day"
        number, time_unit = split_str
        time_unit = lowercase(time_unit)
        time_unit = endswith(time_unit, "s") ? time_unit[1:end-1] : time_unit
        if time_unit == "year"
            Year(number)
        elseif time_unit == "month"
            Month(number)
        elseif time_unit == "day"
            Day(number)
        elseif time_unit == "hour"
            Hour(number)
        elseif time_unit == "minute"
            Minute(number)
        elseif time_unit == "second"
            Second(number)
        else
            error("invalid duration specification '$str'")
        end
    else
        error("invalid duration specification '$str'")
    end
end

parse_duration(int::Int64) = Minute(int)

"""
    match(ts::TimeSlice, tp::TimePattern)

Test whether a time slice matches a time pattern.
A time pattern and a time series match iff, for every time level (year, month, and so on),
the time slice fully contains at least one of the ranges specified in the time pattern for that level.
"""
function match(ts::TimeSlice, tp::TimePattern)
    conds = Array{Bool,1}()
    tp.y != nothing && push!(conds, any(range_in(rng, year(ts.start):year(ts.end_)) for rng in tp.y))
    tp.m != nothing && push!(conds, any(range_in(rng, month(ts.start):month(ts.end_)) for rng in tp.m))
    tp.d != nothing && push!(conds, any(range_in(rng, day(ts.start):day(ts.end_)) for rng in tp.d))
    tp.wd != nothing && push!(conds, any(range_in(rng, dayofweek(ts.start):dayofweek(ts.end_)) for rng in tp.wd))
    tp.H != nothing && push!(conds, any(range_in(rng, hour(ts.start):hour(ts.end_)) for rng in tp.H))
    tp.M != nothing && push!(conds, any(range_in(rng, minute(ts.start):minute(ts.end_)) for rng in tp.M))
    tp.S != nothing && push!(conds, any(range_in(rng, second(ts.start):second(ts.end_)) for rng in tp.S))
    all(conds)
end

"""
    range_in(b::UnitRange{Int64}, a::UnitRange{Int64})

Test whether `b` is fully contained in `a`.
"""
range_in(b::UnitRange{Int64}, a::UnitRange{Int64}) = b.start >= a.start && b.stop <= a.stop
