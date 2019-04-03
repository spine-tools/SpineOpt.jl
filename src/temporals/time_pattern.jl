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

"""
    TimePattern(spec::String)

A `TimePattern` value parsed from the given string specification.
"""
function TimePattern(spec::String)
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


"""
    matches(tp::TimePattern, ts::TimeSlice)

Return `true` iff the given time pattern matches the given time slice.
This means that for every range specified in the time pattern, `ts` is well within that range.
Note that if a range is not specified for a given level, then it doesn't matter where
(or should I say, *when*?) is `t` on that level.
"""
function matches(tp::TimePattern, ts::TimeSlice)
    conds = Array{Bool,1}()
    tp.y != nothing && push!(conds, any(year(ts.start) in rng && year(ts.end_) in rng for rng in tp.y))
    tp.m != nothing && push!(conds, any(month(ts.start) in rng && month(ts.end_) in rng for rng in tp.m))
    tp.d != nothing && push!(conds, any(day(ts.start) in rng && day(ts.end_) in rng for rng in tp.d))
    tp.wd != nothing && push!(conds, any(dayofweek(ts.start) in rng && dayofweek(ts.end_) in rng for rng in tp.wd))
    tp.H != nothing && push!(conds, any(hour(ts.start) in rng && hour(ts.end_) in rng for rng in tp.H))
    tp.M != nothing && push!(conds, any(minute(ts.start) in rng && minute(ts.end_) in rng for rng in tp.M))
    tp.S != nothing && push!(conds, any(second(ts.start) in rng && second(ts.end_) in rng for rng in tp.S))
    all(conds)
end
