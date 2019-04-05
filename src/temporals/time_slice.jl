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


struct TimeSlicePeriod
    start::DateTime
    end_::DateTime
    TimeSlicePeriod(x, y) = x > y ? error("out of order") : new(x, y)
end

mutable struct TimeSlice
    period::TimeSlicePeriod
    JuMP_name::String
end

function Base.show(io::IO, time_slice_period::TimeSlicePeriod)
    print(io, "(start: $(time_slice_period.start), end: $(time_slice_period.end_))")
end

function Base.show(io::IO, time_slice::TimeSlice)
    print(io, "(period: $(time_slice.period), JuMP_name: $(time_slice.JuMP_name))")
end

Base.isless(a::TimeSlice, b::TimeSlice) = Tuple([a.period.start, a.period.end_]) < tuple(b.period.start, b.period.end_)


"""
    before(a::TimeSlice, b::TimeSlice)

Determine whether the end point of `a` is exactly the start point of `b`.
"""
before(a::TimeSlice, b::TimeSlice) = a.period.end_ == b.period.start


"""
    in(b::TimeSlice, a::TimeSlice)

Determine whether `b` is contained in `a`.
"""
Base.in(b::TimeSlice, a::TimeSlice) = b.period.start >= a.period.start && b.period.end_ <= a.period.end_


"""
    overlaps(a::TimeSlice, b::TimeSlice)

Determine whether `a` and `b` overlap.
"""
overlaps(a::TimeSlice, b::TimeSlice) = a.period.start <= b.period.start < a.period.end_ || b.period.start <= a.period.start < b.period.end_
