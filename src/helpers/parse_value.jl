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

"""
    parse_value(db_value, tags...; default)

Parse a database value into a function-like object to be returned by the parameter access function.
Tags associated with the parameter are passed as 'value types' in the `tags` argument,
and the default value is passed in the `default` argument.
The resulting function-like object is ment to be called with an argument such as `(t=t)`
to retrieve a value from the parameter.
"""
function parse_value(db_value::Nothing, tags...; default=nothing)
    if default === nothing
        UnvaluedParameter()
    else
        parse_value(default, tags...; default=nothing)
    end
end

parse_value(db_value::Union{Int64,Float64}, tags...; default=nothing) = ScalarParameter(db_value)

function parse_value(db_value::String, tags...; default=nothing)
    try
        ScalarParameter(parse(Int64, db_value))
    catch
        try
            ScalarParameter(parse(Float64, db_value))
        catch
            ScalarParameter(Symbol(db_value))
        end
    end
end

parse_value(db_value::Array, tags...; default=nothing) = ArrayParameter(db_value)
parse_value(db_value::Dict, tags...; default=nothing) = DictParameter(db_value)

function parse_value(db_value::String, ::Tag{:date_time}; default=nothing)
    ScalarParameter(DateTime(db_value, iso8601dateformat))
end

function parse_value(db_value::String, ::Tag{:duration}; default=nothing)
    split_value = split(db_value, " ")
    if length(split_value) == 1
        # Compact form, eg. "1D"
        number = db_value[1:end-1]
        time_unit = db_value[end]
        duration = if lowercase(time_unit) == "y"
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
            error("invalid duration specification '$db_value'")
        end
        ScalarParameter(duration)
    elseif length(split_value) == 2
        # Verbose form, eg. "1 day"
        number, time_unit = split_value
        time_unit = lowercase(time_unit)
        time_unit = endswith(time_unit, "s") ? time_unit[1:end-1] : time_unit
        duration = if time_unit == "year"
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
            error("invalid duration specification '$db_value'")
        end
        ScalarParameter(duration)
    else
        error("invalid duration specification '$db_value'")
    end
end

function parse_value(db_value::Int64, ::Tag{:duration}; default=nothing)
    ScalarParameter(Minute(db_value))
end

function parse_value(db_value::Array, a::Tag{:duration}; default=nothing)
    ArrayParameter([parse_value(x, a) for x in db_value])
end

function parse_value(db_value::Array, a::Tag{:time_series}; default=nothing)
    parse_value(Dict(k => v for (k, v) in db_value), a; default=default)
end

function parse_value(db_value::Dict, ::Tag{:time_series}; default=nothing)
    d = sort(Dict(DateTime(k) => v for (k, v) in db_value))
    TimeSeriesParameter(collect(keys(d)), collect(values(d)), default)
end

function parse_value(db_value::Dict, ::Tag{:time_pattern}; default=nothing)
    TimePatternParameter(Dict(TimePattern(k) => v for (k, v) in db_value), default)
end

function parse_value(db_value::Dict, a::Tag{:time_series}, b::Tag{:time_pattern}; default=nothing)
    try
        parse_value(db_value, a; default=default)
    catch e
        try
            parse_value(db_value, b; default=default)
        catch e
            parse_value(nothing; default=default)
        end
    end
end

function parse_value(db_value::Dict, a::Tag{:time_pattern}, b::Tag{:time_series}; default=nothing)
    parse_value(db_value, b, a; default=default)
end

"""
    checkout_spinemodeldb(db_url)

Generate and export convenience functions for accessing the database at the given url.
"""
function checkout_spinemodeldb(db_url; upgrade=false)
    checkout_spinedb(db_url; parse_value=parse_value, upgrade=upgrade)
end
