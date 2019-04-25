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
    parse_value(db_value; default, tags...)

Parse a database parameter value into a function-like object to be returned by the function
that accesses the parameter.
The default value is passed in the `default` argument, and tags are passed in the `tags...` argument
"""
function parse_value(db_value::Nothing; default=nothing, tags...)
    if default === nothing
        NoValue()
    else
        parse_value(default; default=nothing, tags...)
    end
end

function parse_value(db_value::Int64; duration=false, kwargs...)
    if duration
        ScalarValue(parse_duration(db_value))
    else
        ScalarValue(db_value)
    end
end

parse_value(db_value::Float64; kwargs...) = ScalarValue(db_value)

function parse_value(db_value::String; date_time=false, duration=false, kwargs...)
    if date_time && duration
        error("uncompatible tags 'date_time' and 'duration'")
    elseif date_time
        ScalarValue(DateTime(db_value, iso8601dateformat))
    elseif duration
        ScalarValue(parse_duration(db_value))
    else
        try
            ScalarValue(parse(Int64, db_value))
        catch
            try
                ScalarValue(parse(Float64, db_value))
            catch
                ScalarValue(Symbol(db_value))
            end
        end
    end
end

function parse_value(db_value::Array; default=nothing, duration=false, time_series=false, kwargs...)
    if duration && time_series
        error("uncompatible tags 'duration' and 'time_series'")
    elseif duration
        ArrayValue(parse_duration.(db_value))
    elseif time_series
        TimeSeriesValue(db_value, default)
    else
        ArrayValue(db_value)
    end
end

function parse_value(db_value::Dict; default=nothing, time_pattern=false, time_series=false, kwargs...)
    if time_pattern && time_series
        try
            TimePatternValue(Dict(TimePattern(k) => v for (k, v) in db_value), default)
        catch
            try
                TimeSeriesValue(db_value, default)
            catch
                parse_value(nothing; default=default)
            end
        end
    elseif time_pattern
        TimePatternValue(Dict(TimePattern(k) => v for (k, v) in db_value), default)
    elseif time_series
        TimeSeriesValue(db_value, default)
    else
        DictValue(db_value)
    end
end
