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

const iso8601dateformat = dateformat"y-m-dTH:M:Sz"

"""
    pack_trailing_dims(dictionary::Dict, n::Int64=1)

An equivalent dictionary where the last `n` dimensions are packed into a matrix
"""
function pack_trailing_dims(dictionary::Dict, n::Int64=1)
    left_dict = Dict{Any,Any}()
    for (key, value) in dictionary
        # TODO: handle length(key) < n and stuff like that?
        left_key = key[1:end-n]
        if length(left_key) == 1
            left_key = left_key[1]
        end
        right_key = key[end-n+1:end]
        right_dict = get!(left_dict, left_key, Dict())
        right_dict[right_key] = value
    end
    Dict(key => reshape([v for (k, v) in sort(collect(value))], :, n) for (key, value) in left_dict)
end


"""
    value(dictionary::Dict)

An equivalent dictionary where values are gathered using `JuMP.value`.
"""
value(dictionary::Dict) = Dict(k => JuMP.value(v) for (k, v) in dictionary)


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
    indexin(t::TimeSlice, p::TimeSeriesParameter)

A pair of indexes in the time series corresponding to the start and end of the time slice.
"""
function indexin(t::TimeSlice, p::TimeSeriesParameter)
    indexin(t.start, t.end_, p.indexes, p.span, p.ignore_year, p.repeat)
end

function indexin(
        start::DateTime,
        end_::DateTime,
        indexes::Union{Array{DateTime,1},StepRange{DateTime,T} where T <: Period},
        span::Period,
        ignore_year::Bool,
        repeat::Bool
    )
    if ignore_year
        start -= Year(start)
        end_ -= Year(end_)
        indexes = [i - Year(i) for i in indexes]
        indexin(start, end_, indexes, span, false, repeat)
    elseif repeat
        if start > indexes[end]
            # Move start and end_ back to indexes range, rather than the other way around
            mismatch = start - indexes[1]
            repetitions = div(mismatch, span)
            start -= repetitions * span
            end_ -= repetitions * span
        end
        indexin(start, end_, indexes, span, ignore_year, false)
    else
        a = findfirst(i -> i >= start, indexes)
        b = findlast(i -> i < end_, indexes)
        a, b
    end
end

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

"""
    checkout_spinemodeldb(db_url)

Generate and export convenience functions for accessing the database at the given url.
"""
function checkout_spinemodeldb(db_url; upgrade=false)
    checkout_spinedb(db_url; parse_value=parse_value, upgrade=upgrade)
end
