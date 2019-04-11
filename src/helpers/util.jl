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
    match(t::TimeSlice, p::TimeSeriesParameter)

A pair of indexes in the time series that best correspond to the start and end of the time slice.
"""
function match(t::TimeSlice, p::TimeSeriesParameter)
    match(t.start, t.end_, p, p.ignore_year, p.repeat)
end

function match(start::DateTime, end_::DateTime, p::TimeSeriesParameter, ignore_year::Bool, repeat::Bool)
    start, end_, p.indexes, repeat, ignore_year
    if repeat
        if start > p.indexes[end]
            # Rewind start and end_ so the former falls within the time series
            # better than advancing all indexes in the time series
            mismatch = start - p.indexes[1]
            repetitions = div(mismatch, p.span)
            start -= repetitions * p.span
            end_ -= repetitions * p.span
        end
        match(start, end_, p, ignore_year, false)
    elseif ignore_year
        a = findfirst(i -> i - Year(i) >= start - Year(start), p.indexes)
        b = findlast(i -> i - Year(i) < end_ - Year(end_), p.indexes)
        a, b
    else
        a = findfirst(i -> i >= start, p.indexes)
        b = findlast(i -> i < end_, p.indexes)
        a, b
    end
end

"""
    checkout_spinemodeldb(db_url)

Generate and export convenience functions for accessing the database at the given url.
"""
function checkout_spinemodeldb(db_url; upgrade=false)
    checkout_spinedb(db_url; parse_value=parse_value, upgrade=upgrade)
end
