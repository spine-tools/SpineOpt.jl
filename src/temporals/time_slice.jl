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

struct TimeSlice <: ObjectLike
    start::DateTime
    end_::DateTime
    duration::Period
    JuMP_name::Union{String,Nothing}
    TimeSlice(x, y, n) = x > y ? error("out of order") : new(x, y, Minute(y - x), n)
end

TimeSlice(start::DateTime, end_::DateTime) = TimeSlice(start, end_, "$start...$end_")

function Base.show(io::IO, time_slice::TimeSlice)
    str = "$(time_slice.start)...$(time_slice.end_)"
    if time_slice.JuMP_name != nothing
        str = "$str ($(time_slice.JuMP_name))"
    end
    print(io, str)
end

"""
    duration(t::TimeSlice)

The duration of time slice `t` (in minutes).
"""
duration(t::TimeSlice) = t.duration.value

start(t::TimeSlice) = t.start
end_(t::TimeSlice) = t.end_

Base.isless(a::TimeSlice, b::TimeSlice) = tuple(a.start, a.end_) < tuple(b.start, b.end_)


"""
    succeeds(a::TimeSlice, b::TimeSlice)

Determine whether the start point of `a` is exactly the end point of `b`.
"""
succeeds(a::TimeSlice, b::TimeSlice) = b.end_ == a.start


"""
    in(b::TimeSlice, a::TimeSlice)

Determine whether `b` is contained in `a`.
"""
Base.in(b::TimeSlice, a::TimeSlice) = b.start >= a.start && b.end_ <= a.end_

"""
    overlaps(a::TimeSlice, b::TimeSlice)

Determine whether `a` and `b` overlap.
"""
overlaps(a::TimeSlice, b::TimeSlice) = a.start <= b.start < a.end_ || b.start <= a.start < b.end_

function overlap_duration(a::TimeSlice, b::TimeSlice)
    overlaps(a, b) || return Minute(0)
    overlap_start = max(a.start, b.start)
    overlap_end = min(a.end_, b.end_)
    Minute(overlap_end - overlap_start)
end

# Iterate single `TimeSlice` as collection. NOTE: This also enables `intersect` with a single `TimeSlice`
# I believe this is correct, since a single `TimeSlice` shouldn't be decomposed by an iterator
# This is also Julia's default behaviour for `Number` types -Manuel
Base.iterate(t::TimeSlice) = iterate((t,))
Base.iterate(t::TimeSlice, state::T) where T = iterate((t,), state)
Base.length(t::TimeSlice) = 1

# Convenience subtraction operator
Base.:-(t::TimeSlice, p::Period) = TimeSlice(t.start - p, t.end_ - p)

"""
    t_lowest_resolution(t_list)

Return the list of the lowest resolution time slices within `t_list`
(those that aren't contained in any other).
"""
function t_lowest_resolution(t_list)
    isempty(t_list) && return t_list
    sort!(t_list)
    result::Array{TimeSlice,1} = [t_list[1]]
    for t in t_list[2:end]
        if result[end] in t
            result[end] = t
        elseif !(t in result[end])
            push!(result, t)
        end
    end
    result
end


"""
    t_highest_resolution(t_list)

Return the list of the highest resolution time slices from `t_list`
(those that don't contain any other).
"""
function t_highest_resolution(t_list)
    isempty(t_list) && return t_list
    sort!(t_list)
    result::Array{TimeSlice,1} = [t_list[1]]
    for t in t_list[2:end]
        result[end] in t || push!(result, t)
    end
    result
end
