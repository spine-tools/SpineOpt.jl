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

struct TimeSeriesParameter{I,V}
    indexes::I
    values::Array{V,1}
    default::V
    adjuster
    function TimeSeriesParameter(i::I, v::Array{V,1}, d, a=x->x) where {I,V}
        if length(i) != length(v)
            error("lengths don't match")
        else
            new{I,V}(i, v, d, a)
        end
    end
end

(p::UnvaluedParameter)(;kwargs...) = nothing
(p::ScalarParameter)(;kwargs...) = p.value

function (p::ArrayParameter)(;i::Union{Int64,Nothing}=nothing)
    i === nothing && error("`i` argument missing")
    p.value[i]
end

function (p::DictParameter)(;k::Union{T,Nothing}=nothing) where T
    k === nothing && error("`k` argument missing")
    p.value[t]
end

function (p::TimePatternParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("`t` argument missing")
    values = [val for (tp, val) in p.dict if matches(tp, t)]
    if isempty(values)
        p.default
    else
        mean(values)
    end
end

function (p::TimeSeriesParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("`t` argument missing")
    a = findfirst(x -> x >= p.adjuster(t.start), p.indexes)
    if a === nothing
        # The time series ends before the time slice starts
        p.default
    else
        b = findlast(x -> x < p.adjuster(t.end_), p.indexes)  # NOTE: `b` can't be `nothing` since a is not `nothing`
        mean(p.values[a:b])
    end
end

# Support basic operations with ScalarParameter
# This is so one can write `parameter(class=object)` instead of `parameter(class=object)()`
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
