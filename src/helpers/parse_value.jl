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
    parse_value(db_value::String, tag_list)

Parse a string according to given tags.
"""
function parse_value(db_value::String, tag_list)
    error_log = []
    for tag in tag_list
        if tag == "date_time"
            try
                return DateTime(db_value, iso8601dateformat)
            catch e
                push!(error_log, e)
            end
        elseif tag == "time_pattern"
            try
                return TimePattern(db_value)
            catch e
                push!(error_log, e)
            end
        end
    end
    SpineInterface.parse_value(db_value, tag_list)
end


function parse_value(db_value::Dict, tag_list)
    if "time_series" in tag_list
        if haskey(db_value, "spec")
            # TODO: return a compact time series somehow
        else
            d = sort(Dict(DateTime(k) => v for (k, v) in db_value))
            TimeSeries(collect(keys(d)), collect(values(d)))
        end
    else
        SpineInterface.parse_value(db_value, tag_list)
    end
end


"""
    parse_value(db_value, tag_list)

Parse any value according to given tags.
"""
parse_value(db_value, tag_list) = SpineInterface.parse_value(db_value, tag_list)
