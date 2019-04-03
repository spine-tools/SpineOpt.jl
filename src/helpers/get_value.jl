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
    get_value(value::Dict{TimePattern,N}, ts::TimeSlice) where N

The value of the first key in the given dictionary that matches the given time slice.
"""
function get_value(value::Dict{TimePattern,N}, ts::TimeSlice) where N
    for (tp, val) in value
        matches(tp, ts) && return val
    end
    error("'$tp' does not match any time pattern")
end

"""
    get_value(value::TimeSeries, ts::TimeSlice) where N

The value of the given time series for the given time slice.
"""
function get_value(value::TimeSeries, ts::TimeSlice)
    # TODO: improve this
    a, b = indexin([ts.start, ts.end_], value.keys)
    mean(value.values[a:b])
end

get_value(value, t) = SpineInterface.get_value(value, t)
