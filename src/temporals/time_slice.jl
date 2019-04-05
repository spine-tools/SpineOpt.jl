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


struct TimeSlice
    start::DateTime
    end_::DateTime
    TimeSlice(x, y) = x > y ? error("out of order") : new(x, y)
end

function Base.show(io::IO, time_slice::TimeSlice)
    print(io, "(start: $(time_slice.start), end: $(time_slice.end_))")
end

Base.isless(a::TimeSlice, b::TimeSlice) = tuple(a.start, a.end_) < tuple(b.start, b.end_)


"""
    before(a::TimeSlice, b::TimeSlice)

Determine whether the end point of `a` is exactly the start point of `b`.
"""
before(a::TimeSlice, b::TimeSlice) = a.end_ == b.start


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
