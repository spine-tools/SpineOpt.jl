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
    ignore_year::Bool
    repeat::Bool
    span::Period
    function TimeSeriesParameter(i::I, v::Array{V,1}, d, iy=false, r=false) where {I,V}
        if length(i) != length(v)
            error("lengths don't match")
        else
            s = r ? i[end] - i[1] : Hour(0)
            new{I,V}(i, v, d, iy, r, s)
        end
    end
end

function TimeSeriesParameter(db_value::Dict, default)
    if !haskey(db_value, "data")
        # Naked dict, no meta
        data = db_value
        metadata = Dict()
    else
        data = db_value["data"]
        metadata = get(db_value, "metadata", Dict())
    end
    TimeSeriesParameter(data, metadata, default)
end

function TimeSeriesParameter(db_value::Array, default)
    # Naked array, no meta
    metadata = Dict()
    TimeSeriesParameter(db_value, metadata, default)
end

function TimeSeriesParameter(data::Dict, metadata::Dict, default)
    # Indexes come with data, so just look for "repeat" and "ignore_year" in metadata
    d = sort(Dict(DateTime(k) => v for (k, v) in data))
    repeat = get(metadata, "repeat", false)
    ignore_year = get(metadata, "ignore_year", false)
    TimeSeriesParameter(collect(keys(d)), collect(values(d)), default, ignore_year, repeat)
end

function TimeSeriesParameter(data::Array, metadata::Dict, default)
    if data[1] isa Array
        # Assume two column array format: make it a dictionary and call the previous constructor
        TimeSeriesParameter(Dict(k => v for (k, v) in data), metadata, default)
    else
        # Assume one column array format
        ignore_year = get(metadata, "ignore_year", false)
        repeat = get(metadata, "repeat", false)
        if haskey(metadata, "start")
            start = DateTime(metadata["start"], iso8601dateformat)
        else
            start = DateTime(1)
            ignore_year = true
            repeat = true
        end
        len = length(data) - 1
        if haskey(metadata, "resolution")
            resolution = metadata["resolution"]
            if resolution isa Array
                rlen = length(resolution)
                if rlen > len
                    # Trim
                    resolution = resolution[1:len]
                elseif rlen < len
                    # Repeat
                    ratio = div(len, rlen)
                    tail_len = len - ratio * rlen
                    tail = resolution[1:tail_len]
                    resolution = vcat(repeat(resolution, ratio), tail)
                end
                res = parse_duration.(resolution)
                inds = cumsum(vcat(start, res))
            else
                res = parse_duration(resolution)
                end_ = start + len * res
                inds = start:res:end_
            end
        else
            res = Hour(1)
            end_ = start + len * res
            inds = start:res:end_
        end
        TimeSeriesParameter(inds, data, default, ignore_year, repeat)
    end
end

(p::UnvaluedParameter)(;kwargs...) = nothing
(p::ScalarParameter)(;kwargs...) = p.value

function (p::ArrayParameter)(;i::Union{Int64,Nothing}=nothing)
    i === nothing && error("argument `i` missing")
    p.value[i]
end

function (p::DictParameter)(;k::Union{T,Nothing}=nothing) where T
    k === nothing && error("argument `k` missing")
    p.value[t]
end

function (p::TimePatternParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("argument `t` missing")
    values = [val for (tp, val) in p.dict if match(t, tp)]
    if isempty(values)
        @warn("$t does not match $p, using default value...")
        p.default
    else
        mean(values)
    end
end

function (p::TimeSeriesParameter)(;t::Union{TimeSlice,Nothing}=nothing)
    t === nothing && error("argument `t` missing")
    a, b = indexin(t, p)
    if a === nothing || b === nothing || b < a
        @warn("$p is not defined on $t, using default value...")
        p.default
    else
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
