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
struct UnvaluedParameter
end

struct ScalarParameter{T}
    value::T
end

struct ArrayParameter
    value::Array
end

struct DictParameter
    value::Dict
end

struct TimePatternParameter
    dict::Dict{TimePattern,T} where T
    default
end

struct TimeSeriesParameter
    keys::Array{DateTime,1}
    values::Array{T,1} where T
    default
    TimeSeriesParameter(k, v, d) = length(k) != length(v) ? error("lengths don't match") : new(k, v, d)
end

(p::UnvaluedParameter)(;t=nothing) = nothing
(p::ScalarParameter)(;t=nothing) = p.value

function (p::ArrayParameter)(;t::Union{Int64,Nothing}=nothing)
    t === nothing && error("`t` argument missing")
    p.value[t]
end

function (p::DictParameter)(;t::Union{T,Nothing}=nothing) where T
    t === nothing && error("`t` argument missing")
    p.value[t]
end

function (p::TimePatternParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("`t` argument missing")
    for (tp, val) in p.dict
        matches(tp, t) && return val
    end
    p.default
end

function (p::TimeSeriesParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("`t` argument missing")
    a = findfirst(x -> x >= t.start, p.keys)
    a === nothing && return p.default
    b = findlast(x -> x < t.end_, p.keys)  # NOTE: `b` can't be `nothing` since a != `nothing` and `t` is well defined
    mean(p.values[a:b])
end

# Support basic operations with ScalarParameter
# This is so one can write `parameter(class=object)` instead of `parameter(class=object)()`
import Base: convert, +, -, *, /, <

convert(::Type{T}, x::ScalarParameter{T}) where {T} = x.value

+(x::ScalarParameter{T}, y::N) where {T,N} = x.value + y
-(x::ScalarParameter{T}, y::N) where {T,N} = x.value - y
*(x::ScalarParameter{T}, y::N) where {T,N} = x.value * y
/(x::ScalarParameter{T}, y::N) where {T,N} = x.value / y
<(x::ScalarParameter{T}, y::N) where {T,N} = isless(x.value, y)
+(x::N, y::ScalarParameter{T}) where {T,N} = x + y.value
-(x::N, y::ScalarParameter{T}) where {T,N} = x - y.value
*(x::N, y::ScalarParameter{T}) where {T,N} = x * y.value
/(x::N, y::ScalarParameter{T}) where {T,N} = x / y.value
<(x::N, y::ScalarParameter{T}) where {T,N} = isless(x, y.value)
+(x::ScalarParameter{T}, y::ScalarParameter{N}) where {T,N} = x.value + y.value
-(x::ScalarParameter{T}, y::ScalarParameter{N}) where {T,N} = x.value - y.value
*(x::ScalarParameter{T}, y::ScalarParameter{N}) where {T,N} = x.value * y.value
/(x::ScalarParameter{T}, y::ScalarParameter{N}) where {T,N} = x.value / y.value
<(x::ScalarParameter{N}, y::ScalarParameter{T}) where {T,N} = isless(x.value, y.value)
