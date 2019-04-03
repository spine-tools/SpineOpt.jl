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
    parse_time_pattern(spec::String)

Parse the given time pattern specification as a `TimePattern` value.
"""
function parse_time_pattern(spec::String)
    union_op = ","
    intersection_op = ";"
    range_op = "-"
    kwargs = Dict()
    regexp = r"(y|m|d|wd|H|M|S)"
    pattern_specs = split(spec, union_op)
    for pattern_spec in pattern_specs
        range_specs = split(pattern_spec, intersection_op)
        for range_spec in range_specs
            m = match(regexp, range_spec)
            m === nothing && error("""invalid interval specification $range_spec.""")
            key = m.match
            start_stop = range_spec[length(key)+1:end]
            start_stop = split(start_stop, range_op)
            length(start_stop) != 2 && error("""invalid interval specification $range_spec.""")
            start_str, stop_str = start_stop
            start = try
                parse(Int64, start_str)
            catch ArgumentError
                error("""invalid lower bound $start_str.""")
            end
            stop = try
                parse(Int64, stop_str)
            catch ArgumentError
                error("""invalid upper bound $stop_str.""")
            end
            start > stop && error("""lower bound can't be higher than upper bound.""")
            arr = get!(kwargs, Symbol(key), Array{UnitRange{Int64},1}())
            push!(arr, range(start, stop=stop))
        end
    end
    TimePattern(;kwargs...)
end


"""
    parse_value(db_value::String, tag_list)

An equivalent value, parsed according to given tags.
"""
function parse_value(db_value::String, tag_list)
    format = dateformat"y-m-dTH:M:S"  # Let's use this, ISO 8601 I guess...
    if "date_time" in tag_list
        DateTime(db_value, format)
    elseif "time_pattern" in tag_list
        parse_time_pattern(db_value)
    else
        SpineInterface.parse_value(db_value)
    end
end


"""
    parse_value(db_value::Dict, tag_list)

An equivalent value, parsed according to given tags.
"""
function parse_value(db_value::Dict, tag_list)
    # TODO: finalize JSON specification and update this
    haskey(db_value, "type") || error("'type' missing")
    type_ = db_value["type"]
    if type_ == "time_pattern"
        haskey(db_value, "data") || error("'data' missing")
        db_value["data"] isa Dict || error("'data' should be a dictionary (time_pattern: value)")
        db_value["time_pattern_data"] = Dict{Union{TimePattern,String},Any}()
        # Try and parse String keys as TimePatterns into a new dictionary
        for (k, v) in pop!(db_value, "data")
            new_k = try
                parse_time_pattern(k)
            catch e
                k
            end
            db_value["time_pattern_data"][new_k] = v
        end
        db_value
    else
        error("unknown type '$type_'")
    end
end


"""
    parse_value(db_value, tag_list)

An equivalent value, parsed according to given tags.
"""
parse_value(db_value, tag_list) = SpineInterface.parse_value(db_value, tag_list)
