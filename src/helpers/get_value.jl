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
    get_value(value, t::Union{Int64,TimeSlice,Nothing})

A value corresponding to index `t` in `value`.
Called internally by convenience functions to retrieve parameter values.

- If `value` is an `Array`, then:
    - if `t` is not `nothing`, return index `t` in `value`, otherwise return `value`.
- If `value` is a `TimePattern`, then:
    - it `t` is not `nothing`, return `true` or `false` depending on whether or not `value` matches `t`;
    - otherwise return `value`.
- If `value` is a `Dict`, then:
  - If `value["type"]` is "time_pattern", then return thet first value from `value["time_pattern_data"]`
  that matches `t`.
  - More to come...
- If `value` is a scalar, then return `value`.
"""
function get_value(value::Any, t::Union{Int64,TimeSlice,Nothing})
    if value isa Array
        if t === nothing
            value
        else
            value[t]
        end
    elseif value isa TimePattern
        if t === nothing
            value
        else
            matches(value, t)
        end
    elseif value isa Dict
        # Fun begins
        # TODO: Finalize JSON spec and update this
        type_ = value["type"]
        if type_ == "time_pattern"
            t === nothing && error("argument `t` missing")
            time_pattern_data = value["time_pattern_data"]
            for (k, v) in time_pattern_data
                time_pattern = if k isa TimePattern
                    k
                else
                    try
                        eval(Symbol(k))()
                    catch e
                        if e isa UndefVarError
                            error("unknown time pattern '$k'")
                        else
                            rethrow()
                        end
                    end
                end
                matches(time_pattern, t) && return v
            end
            error("'$t' does not match any time pattern")
        else
            error("unknown type '$type_'")
        end
    else
        value
    end
end
