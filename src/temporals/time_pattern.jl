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
    TimePattern(...)
"""
struct TimePattern
    y::Union{Array{UnitRange{Int64},1},Nothing}
    m::Union{Array{UnitRange{Int64},1},Nothing}
    d::Union{Array{UnitRange{Int64},1},Nothing}
    wd::Union{Array{UnitRange{Int64},1},Nothing}
    H::Union{Array{UnitRange{Int64},1},Nothing}
    M::Union{Array{UnitRange{Int64},1},Nothing}
    S::Union{Array{UnitRange{Int64},1},Nothing}
    TimePattern(;y=nothing, m=nothing, d=nothing, wd=nothing, H=nothing, M=nothing, S=nothing) = new(y, m, d, wd, H, M, S)
end


function Base.show(io::IO, time_pattern::TimePattern)
    d = Dict{Symbol,String}(
        :y => "year",
        :m => "month",
        :d => "day",
        :wd => "day of the week",
        :H => "hour",
        :M => "minute",
        :S => "second",
    )
    ranges = Array{String,1}()
    for field in fieldnames(TimePattern)
        value = getfield(time_pattern, field)
        if value != nothing
            str = "$(d[field]) from "
            str *= join(["$(x.start) to $(x.stop)" for x in value], ", or ")
            push!(ranges, str)
        end
    end
    print(io, join(ranges, ",\nand "))
end


matches(time_pattern::TimePattern, str::String) = matches(time_pattern, parse_date_time_str(str))


"""
    matches(time_pattern::TimePattern, t::DateTime)

Return `true` iff the given time pattern matches the given `t`.
This means that for every range specified in the time pattern, `t` is well in that range.
Note that if a range is not specified for a given level, then it doesn't matter where
(or should I say, *when*?) is `t` on that level.
"""
function matches(time_pattern::TimePattern, t::DateTime)
    conds = Array{Bool,1}()
    time_pattern.y != nothing && push!(conds, any(year(t) in rng for rng in time_pattern.y))
    time_pattern.m != nothing && push!(conds, any(month(t) in rng for rng in time_pattern.m))
    time_pattern.d != nothing && push!(conds, any(day(t) in rng for rng in time_pattern.d))
    time_pattern.wd != nothing && push!(conds, any(dayofweek(t) in rng for rng in time_pattern.wd))
    time_pattern.H != nothing && push!(conds, any(hour(t) in rng for rng in time_pattern.H))
    time_pattern.M != nothing && push!(conds, any(minute(t) in rng for rng in time_pattern.M))
    time_pattern.S != nothing && push!(conds, any(second(t) in rng for rng in time_pattern.S))
    all(conds)
end
