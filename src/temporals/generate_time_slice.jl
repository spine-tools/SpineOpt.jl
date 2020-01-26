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
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    time_slices::Array{TimeSlice,1}
    function TimeSliceSet(block_time_slices)
        time_slices = sort(unique(t for v in values(block_time_slices) for t in v))
        new(block_time_slices, time_slices)
    end
end

struct ToTimeSlice
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    block_time_slice_map::Dict{Object,Array{Int64,1}}
    function ToTimeSlice(block_time_slices)
        block_time_slice_map = Dict{Object,Array{Int64,1}}()
        for (block, time_slices) in block_time_slices
            isempty(time_slices) && continue
            temp_block_start = start(first(time_slices))
            temp_block_end = end_(last(time_slices))
            m = block_time_slice_map[block] = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
            for (ind, t) in enumerate(time_slices)
                first_minute = Minute(start(t) - temp_block_start).value + 1
                last_minute = Minute(end_(t) - temp_block_start).value
                m[first_minute:last_minute] .= ind
            end
        end
        new(block_time_slices, block_time_slice_map)
    end
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
    rolling_windows()

A tuple of start and end time for the main rolling window.
"""
function generate_current_window()
    instance = first(model())
    model_start_ = model_start(model=instance)
    model_end_ = model_end(model=instance)
    roll_forward_ = roll_forward(model=instance, _strict=false)
    window_start = model_start_
    window_end = (roll_forward_ === nothing) ? model_end_ : min(model_start_ + roll_forward_, model_end_)
    current_window = TimeSlice(window_start, window_end)
    @eval begin
        current_window = $current_window
    end
end


# Adjuster functions, in case blocks specify their own start and end
adjusted_start(window_start, window_end, ::Nothing) = window_start
adjusted_start(window_start, window_end, blk_start::Union{Period,CompoundPeriod}) = window_start + blk_start
adjusted_start(window_start, window_end, blk_start::DateTime) = max(window_start, blk_start)

adjusted_end(window_start, window_end, ::Nothing) = window_end
adjusted_end(window_start, window_end, blk_end::Union{Period,CompoundPeriod}) = 
    max(window_end, window_start + blk_end)
adjusted_end(window_start, window_end, blk_end::DateTime) = max(window_end, blk_end)


"""
    block_time_intervals(window_start, window_end)

A `Dict` mapping temporal blocks to a sorted `Array` of time intervals, i.e., (start, end) tuples.
"""
function block_time_intervals(window_start, window_end)
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


function block_time_slices(block_time_intervals)
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


"""
    block_time_slices(window_start, window_end)

A `Dict` mapping temporal blocks to a sorted `Array` of `TimeSlices`.
"""
block_time_slices(window_start, window_end) = block_time_slices(block_time_intervals(window_start, window_end))


"""
    generate_time_slice(window_start, window_end)

Create and export a `TimeSliceSet` containing `TimeSlice`s in the given window.
Return an `Array` of all `TimeSlice`s in the model (including history).

See [@TimeSliceSet()](@ref).
"""
function generate_time_slice()
    window_start = start(current_window)
    window_end = end_(current_window)
    window_span = window_end - window_start
    window_block_time_slices = block_time_slices(window_start, window_end)
    time_slice = TimeSliceSet(window_block_time_slices)
    t_history_t = Dict(t => t - window_span for t in time_slice() if end_(t) <= window_end)
    all_block_time_slices = Dict(
        block => [[t_history_t[t] for t in time_slices if end_(t) <= window_end]; time_slices]
        for (block, time_slices) in window_block_time_slices
    )
    to_time_slice = ToTimeSlice(all_block_time_slices)    
    all_time_slices = sort(unique(t for v in values(all_block_time_slices) for t in v))
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        t_history_t = $t_history_t
        all_time_slices = $all_time_slices
        export time_slice
        export to_time_slice
    end
end


function roll_temporal_structure()
    instance = first(model())
    end_(current_window) >= model_end(model=instance) && return false
    roll_forward_ = roll_forward(model=instance, _strict=false)
    roll_forward_ === nothing && return false
    roll!(current_window, roll_forward_)
    roll!.(all_time_slices, roll_forward_)
    true
end