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

import Dates: CompoundPeriod

struct TimeSliceSet
    time_slices::Array{TimeSlice,1}
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
end

struct ToTimeSlice
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    block_time_slice_map::Dict{Object,Array{Int64,1}}
end

"""
    time_slice(;temporal_block=anything, t=anything)

An `Array` of time slices *in the model*.
- `temporal_block` is a temporal block object to filter the result.
- `t` is a `TimeSlice` or collection of `TimeSlice`s *in the model* to filter the result.
"""
(h::TimeSliceSet)(;temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, s) = s
(h::TimeSliceSet)(temporal_block::Object, s) = [t for t in s if temporal_block in t.blocks]
(h::TimeSliceSet)(temporal_blocks::Array{Object,1}, s) = [t for blk in temporal_blocks for t in h(blk, s)]


"""
    to_time_slice(t...)

An array of time slices *in the model* that overlap `t`
(where `t` may not be in the model).
"""
function (h::ToTimeSlice)(t::Union{TimeSlice,DateTime}...)
    mapped = Array{TimeSlice,1}()
    for (blk, time_slice_map) in h.block_time_slice_map
        time_slices = h.block_time_slices[blk]
        append!(mapped, mapped_time_slices(time_slice_map, time_slices, t...))
    end
    unique(mapped)
end

"""
    mapped_time_slices(time_slice_map, time_slices, t...)

An array of all time slices in `time_slices` that overlap any `t`.
"""
function mapped_time_slices(time_slice_map, time_slices, t::TimeSlice...)
    mapped = Array{TimeSlice,1}()
    block_start = start(first(time_slices))
    block_end = end_(last(time_slices))
    for s in t
        s_start = max(block_start, start(s))
        s_end = min(block_end, end_(s))
        s_end <= s_start && continue
        first_ind = time_slice_map[Minute(s_start - block_start).value + 1]
        last_ind = time_slice_map[Minute(s_end - block_start).value]
        append!(mapped, time_slices[first_ind:last_ind])
    end
    mapped
end


function mapped_time_slices(time_slice_map, time_slices, t::DateTime...)
    block_start = start(first(time_slices))
    block_end = end_(last(time_slices))
    [time_slices[time_slice_map[Minute(s - block_start).value + 1]] for s in t if block_start <= s < block_end]
end


"""
    _rolling_windows(from::Dates.DateTime, step::Union{Period,CompoundPeriod}, until::DateTime)

An array of tuples of start and end time for each rolling window.
"""
function _rolling_windows(from::Dates.DateTime, step::Union{Period,CompoundPeriod}, until::DateTime)
    windows = Array{Tuple{DateTime,DateTime},1}()
    while from < until
        push!(windows, (from, from + step))
        from += step
    end
    windows
end


"""
    rolling_windows()

An array of tuples of start and end time for each rolling window.
"""
function rolling_windows()
    instance = first(model())
    m_start = model_start(model=instance)
    m_end = model_end(model=instance)
    m_roll_forward = roll_forward(model=instance, _strict=false)
    m_roll_forward === nothing && return [(m_start, m_end)]
    _rolling_windows(m_start, m_roll_forward, m_end)
end

# Adjuster functions, in case blocks specify their own start and end
adjusted_start(window_start, window_end, ::Nothing) = window_start
adjusted_start(window_start, window_end, blk_start::Union{Period,CompoundPeriod}) = window_start + blk_start
adjusted_start(window_start, window_end, blk_start::DateTime) = max(window_start, blk_start)

adjusted_end(window_start, window_end, ::Nothing) = window_end
adjusted_end(window_start, window_end, blk_end::Union{Period,CompoundPeriod}) = max(window_end, window_start + blk_end)
adjusted_end(window_start, window_end, blk_end::DateTime) = max(window_end, blk_end)


"""
    _block_time_intervals(window_start, window_end)

A `Dict` mapping temporal blocks to a sorted `Array` of time intervals, i.e., (start, end) tuples.
"""
function _block_time_intervals(window_start, window_end)
    d = Dict{Object,Array{Tuple{DateTime,DateTime},1}}()
    for block in temporal_block()
        time_intervals = Array{Tuple{DateTime,DateTime},1}()
        block_start_ = adjusted_start(window_start, window_end, block_start(temporal_block=block, _strict=false))
        block_end_ = adjusted_end(window_start, window_end, block_end(temporal_block=block, _strict=false))
        time_slice_start = block_start_
        i = 1
        while time_slice_start < block_end_
            duration = resolution(temporal_block=block, i=i)
            time_slice_end = time_slice_start + duration
            if time_slice_end > block_end_
                time_slice_end = block_end_
                @warn(
                    """
                    the last time slice of temporal block $block has been cut to fit within the optimisation window
                    """
                )
            end
            push!(time_intervals, (time_slice_start, time_slice_end))
            time_slice_start = time_slice_end
            i += 1
        end
        d[block] = time_intervals
    end
    d
end


function _block_time_slices(block_time_intervals)
    inv_block_time_intervals = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    for (block, time_intervals) in block_time_intervals
        for t in time_intervals
            push!(get!(inv_block_time_intervals, t, Array{Object,1}()), block)
        end
    end
    instance = first(model())
    d = Dict(:minute => Minute, :hour => Hour)
    duration_unit_ = get(d, duration_unit(model=instance, _strict=false), Minute)
    Dict(
        block => [
            TimeSlice(t..., inv_block_time_intervals[t]...; duration_unit=duration_unit_)
            for t in time_intervals
        ]
        for (block, time_intervals) in block_time_intervals
    )
end


function _block_time_slice_map(block_time_slices)
    d = Dict{Object,Array{Int64,1}}()
    for (block, time_slices) in block_time_slices
        isempty(time_slices) && continue
        temp_block_start = start(first(time_slices))
        temp_block_end = end_(last(time_slices))
        d[block] = time_slice_map = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
        for (ind, t) in enumerate(time_slices)
            first_minute = Minute(start(t) - temp_block_start).value + 1
            last_minute = Minute(end_(t) - temp_block_start).value
            time_slice_map[first_minute:last_minute] .= ind
        end
    end
    d
end


"""
    generate_time_slice(window_start, window_end)

Generate and export a convenience functor called `time_slice`, that can be used to retrieve
time slices in the model between `window_start` and `window_end`. See [@TimeSliceSet()](@ref).
"""
function generate_time_slice(window_start, window_end)
    block_time_intervals = _block_time_intervals(window_start, window_end)
    block_time_slices = _block_time_slices(block_time_intervals)
    time_slices = sort(unique(t for v in values(block_time_slices) for t in v))
    time_slice = TimeSliceSet(copy(time_slices), deepcopy(block_time_slices))
    prepend_history!(time_slices, block_time_slices, window_start)
    block_time_slice_map = _block_time_slice_map(block_time_slices)
    to_time_slice = ToTimeSlice(block_time_slices, block_time_slice_map)
    @eval begin
        to_time_slice = $to_time_slice
        time_slice = $time_slice
        export to_time_slice
        export time_slice
    end
    time_slices
end


function prepend_history!(time_slices, block_time_slices, window_start)
    history_time_slices = SpineModel.time_slice.time_slices
    block_history_time_slices = SpineModel.time_slice.block_time_slices
    history_start_ = history_start(window_start, time_slices)
    filter!(x -> iscontained(history_start_, x) && x.end_ <= window_start, history_time_slices)
    prepend!(time_slices, history_time_slices)
    for (block, history_time_slices) in block_history_time_slices
        filter!(x -> iscontained(history_start_, x) && x.end_ <= window_start, history_time_slices)
        prepend!(block_time_slices[block], history_time_slices)
    end
end


_minimum_start(ref, iter) = isempty(iter) ? ref : minimum(ref - x for x in iter)

function history_start(window_start, time_slices)
    trans_delay_start = _minimum_start(
        window_start, trans_delay(;inds..., t=t) for inds in indices(trans_delay) for t in time_slices
    )
    min_up_time_start = _minimum_start(
        window_start, min_up_time(unit=u, t=t) for u in indices(min_up_time) for t in time_slices
    )
    min_down_time_start = _minimum_start(
        window_start, min_down_time(unit=u, t=t) for u in indices(min_down_time) for t in time_slices
    )
    time_slice_start = _minimum_start(window_start, (end_(t) - start(t)) for t in time_slices)
    min(trans_delay_start, min_up_time_start, min_down_time_start, time_slice_start)
end


function init_time_slice()
    instance = first(model())
    model_start_ = model_start(model=instance)
    duration_unit_ = get(
        Dict(:minute => Minute, :hour => Hour), duration_unit(model=instance, _strict=false), Minute
    )
    date_times = Array{DateTime,1}()
    for (u, n, d) in indices(fix_flow)
        fix_flow(unit=u, node=n, direction=d) isa TimeSeries || continue
        append!(date_times, fix_flow(unit=u, node=n, direction=d).indexes)
    end
    for (conn, n, d) in indices(fix_trans)
        fix_trans(connection=conn, node=n, direction=d) isa TimeSeries || continue
        append!(date_times, fix_trans(connection=conn, node=n, direction=d).indexes)
    end
    for stor in indices(fix_stor_state)
        fix_stor_state(storage=stor) isa TimeSeries || continue
        append!(date_times, fix_stor_state(storage=stor).indexes)
    end
    for u in indices(fix_units_on)
        fix_units_on(unit=u) isa TimeSeries || continue
        append!(date_times, fix_units_on(unit=u).indexes)
    end
    filter!(t -> t <= model_start_, date_times)
    push!(date_times, model_start_)
    sort!(date_times)
    unique!(date_times)
    time_slices = [
        TimeSlice(start, end_, temporal_block()...; duration_unit=duration_unit_) 
        for (start, end_) in zip(date_times[1:end - 1], date_times[2:end])
    ]
    block_time_slices = Dict(block => copy(time_slices) for block in temporal_block())
    time_slice = TimeSliceSet(time_slices, block_time_slices)
    @eval begin
        time_slice = $time_slice
        export time_slice
    end
end