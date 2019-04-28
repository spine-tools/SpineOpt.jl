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

mutable struct TimeSlice
    start::DateTime
    end_::DateTime
    duration::Period
    JuMP_name::Union{String,Nothing}
    TimeSlice(x, y, n) = x > y ? error("out of order") : new(x, y, Minute(y - x), n)
end

TimeSlice(start::DateTime, end_::DateTime) = TimeSlice(start, end_, nothing)

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
    intersect(b::Array{TimeSlice,1}, a::TimeSlice)

Determine if two TimeSlices intersect.
"""
Base.intersect(b::Array{TimeSlice,1}, a::TimeSlice) = intersect(b,[a])


"""
    intersect(b::TimeSlice, a::Array{TimeSlice,1})

Determine if two TimeSlices intersect.
"""
Base.intersect(b::TimeSlice, a::Array{TimeSlice,1}) = intersect([b],a)


"""
    intersect(b::TimeSlice, a::TimeSlice)

Determine if two TimeSlices intersect.
"""
Base.intersect(b::TimeSlice, a::TimeSlice) = intersect([b],[a])


"""
    overlaps(a::TimeSlice, b::TimeSlice)

Determine whether `a` and `b` overlap.
"""
overlaps(a::TimeSlice, b::TimeSlice) = a.start <= b.start < a.end_ || b.start <= a.start < b.end_

Base.iterate(t::TimeSlice) = iterate((t,))
Base.iterate(t::TimeSlice, state::T) where T = iterate((t,), state)

"""
    t_lowest_resolution(t_list::Union{TimeSlice,Array{TimeSlice,1}})

Return the list of the lowest resolution time slices within `t_list`
(those that aren't contained in any other).
"""
function t_lowest_resolution(t_list::Array{TimeSlice,1})
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
    t_highest_resolution(t_list::Union{TimeSlice,Array{TimeSlice,1}})

Return the list of the highest resolution time slices from `t_list`
(those that don't contain any other).
"""
function t_highest_resolution(t_list::Array{TimeSlice,1})
    isempty(t_list) && return t_list
    sort!(t_list)
    result::Array{TimeSlice,1} = [t_list[1]]
    for t in t_list[2:end]
        result[end] in t || push!(result, t)
    end
    result
end


"""
    t_in_t_list(t::TimeSlice, t_list)

Determine whether or not the time slice `t` is an element of the list of time slices `t_list`.
"""
t_in_t_list(t::TimeSlice, t_list) = t_list == :any ? true : (t in tuple(t_list...))
