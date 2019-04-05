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
    parse_value(db_value::String, ::Tag{:date_time})

Parse a string according to given tags.
"""
function parse_value(db_value::String, ::Tag{:date_time}; default=nothing)
    DateTimeParameter(db_value, iso8601dateformat)
end

function parse_value(db_value::String; default=nothing)
    try
        parse(Int64Parameter, db_value)
    catch
        try
            parse(Float64Parameter, db_value)
        catch
            SymbolParameter(db_value)
        end
    end
end

parse_value(db_value::Int64, tags...; default=nothing) = Int64Parameter(db_value)
parse_value(db_value::Float64, tags...; default=nothing) = Float64Parameter(db_value)
parse_value(db_value::Array, tags...; default=nothing) = ArrayParameter(db_value)

function parse_value(db_value::Nothing, tags...; default=nothing)
    if default === nothing
        NothingParameter()
    else
        parse_value(default, tags...; default=nothing)
    end
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
Use custom `parse_value` and `get_value`.
"""
function checkout_spinemodeldb(db_url; upgrade=false)
    checkout_spinedb(db_url; parse_value=parse_value, upgrade=upgrade)
end
