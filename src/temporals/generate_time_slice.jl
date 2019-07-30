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
struct TimeSliceFunctor
    time_slices::Array{TimeSlice,1}
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
end

struct ToTimeSliceFunctor
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    block_time_slice_map::Dict{Object,Array{Int64,1}}
end

"""
    time_slice(;temporal_block=anything, t=anything)

An `Array` of time slices *in the model*.
- `temporal_block` is a temporal block object used to filter the result by.
- `t` is a `TimeSlice` or collection of `TimeSlice`s to filter the result by.
"""
function (f::TimeSliceFunctor)(;temporal_block=anything, t=anything)
    temporal_block === t === anything && return f.time_slices
    temporal_block_ = intersect(keys(f.block_time_slices), Object.(temporal_block))
    # Break `t` into a dictionary keyed by temporal block
    if t === anything
        block_time_slices = Dict{Object,Anything}(blk => anything for blk in temporal_block_)
    else
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t_ in t
            for blk in intersect(t_.blocks, temporal_block_)
                push!(get!(block_time_slices, blk, TimeSlice[]), t_)
            end
        end
    end
    sort(
        unique(
            t for blk in keys(block_time_slices) for t in intersect(f.block_time_slices[blk], block_time_slices[blk])
        )
    )
end


"""
    to_time_slice(t::TimeSlice...)

An array of time slices *in the model* that overlap `t`
(where `t` may not be in the model).
"""
function (f::ToTimeSliceFunctor)(t::TimeSlice...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, time_slice_map) in f.block_time_slice_map
        temp_block_start = start(first(f.block_time_slices[blk]))
        temp_block_end = end_(last(f.block_time_slices[blk]))
        ranges = []
        for s in t
            s_start = max(temp_block_start, start(s))
            s_end = min(temp_block_end, end_(s))
            s_end <= s_start && continue
            first_ind = time_slice_map[Minute(s_start - temp_block_start).value + 1]
            last_ind = time_slice_map[Minute(s_end - temp_block_start).value]
            push!(ranges, first_ind:last_ind)
        end
        isempty(ranges) && continue
        push!(blk_rngs, (blk, union(ranges...)))
    end
    unique(t for (blk, rngs) in blk_rngs for t in f.block_time_slices[blk][rngs])
end

"""
    to_time_slice(t::DateTime...)

An array of time slices *in the model* that overlap `t`.
"""
function (f::ToTimeSliceFunctor)(t::DateTime...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, time_slice_map) in f.block_time_slice_map
        temp_block_start = start(first(f.block_time_slices[blk]))
        temp_block_end = end_(last(f.block_time_slices[blk]))
        rngs = [
            time_slice_map[Minute(s - temp_block_start).value + 1]
            for s in t if temp_block_start <= s < temp_block_end
        ]
        push!(blk_rngs, (blk, rngs))
    end
    unique(t for (blk, rngs) in blk_rngs for t in f.block_time_slices[blk][rngs])
end

"""
    block_time_slices()

A `Dict` mapping temporal blocks to a sorted `Array` of `TimeSlice`s in that block.
"""
function block_time_slices()
    result = Dict{Object,Array{TimeSlice,1}}()
    for blk in temporal_block()
        time_slices = Array{TimeSlice,1}()
        temp_block_start = start_datetime(temporal_block=blk)
        temp_block_end = end_datetime(temporal_block=blk)
        time_slice_start = temp_block_start
        i = 1
        while time_slice_start < temp_block_end
            duration = time_slice_duration(temporal_block=blk, i=i)
            time_slice_end = time_slice_start + duration
            if time_slice_end > temp_block_end
                time_slice_end = temp_block_end
                @warn(
                    """
                    the duration of the last time slice of temporal block $blk has been reduced
                    to respect the specified end time
                    """
                )
            end
            push!(time_slices, TimeSlice(time_slice_start, time_slice_end))
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
        result[blk] = time_slices
    end
    result
end

"""
    block_time_slices_split(rolling=:default)

Like [`block_time_slices()`](@ref) but split among 'windows' in the given rolling object.
"""
function window_block_time_slices(rolling=:default)
    # Compute `windows` and `initial_condition_windows` look-backs if possible
    windows = Array{TimeSlice,1}()
    initial_condition_windows = Array{TimeSlice,1}()
    horizon_start = horizon_start_datetime(rolling=rolling)
    horizon_init_cond_start = horizon_start - initial_condition_duration(rolling=rolling, i=1)
    horizon_end = horizon_end_datetime(rolling=rolling)
    window_start = horizon_start
    i = 1
    while window_start < horizon_end
        window_dur = rolling_window_duration(rolling=rolling, i=i)
        initial_condition_dur = initial_condition_duration(rolling=rolling, i=i)
        reoptimization_freq = reoptimization_frequency(rolling=rolling, i=i)
        window_end = window_start + window_dur
        if window_end > horizon_end
            window_end = horizon_end
        end
        initial_condition_start = window_start - initial_condition_dur
        push!(windows, TimeSlice(window_start, window_end))
        push!(initial_condition_windows, TimeSlice(initial_condition_start, window_start))
        window_start += reoptimization_freq
        i += 1
    end
    # Build map of windows and initial condition windows in the entire horizon
    horizon_minutes = Minute(horizon_end - horizon_start).value
    window_map = [Array{Int64,1}() for i in 1:horizon_minutes]
    initial_condition_window_map = [Array{Int64,1}() for i in 1:horizon_minutes]
    for (ind, window) in enumerate(windows)
        for x in start(window):Minute(1):end_(window) - Minute(1)
            push!(window_map[Minute(x - horizon_start).value + 1], ind)
        end
    end
    for (ind, initial_condition_window) in enumerate(initial_condition_windows)
        for x in start(initial_condition_window):Minute(1):end_(initial_condition_window) - Minute(1)
            push!(initial_condition_window_map[Minute(x - horizon_init_cond_start).value + 1], ind)
        end
    end
    if isempty(windows)
        # No windows, can't do any split
        [block_time_slices()]
    else
        # Do split
        window_block_time_slices = [Dict{Object,Array{TimeSlice,1}}() for i in 1:length(windows)]
        for (block, time_slices) in block_time_slices()
            # We need a different block for the time slices in the look back zone,
            # since we don't want to 'track' variables here
            # TODO: Fix name ambiguity
            block_initial_condition = Object(Symbol(block.name, "_initial_condition"))
            for t in time_slices
                t_start = start(t)
                t_end = end_(t)
                # Get overlapping windows
                window_indexes = unique(
                    i
                    for x in t_start:Minute(1):t_end - Minute(1)
                    for i in get(window_map, Minute(x - horizon_start).value + 1, ())
                )
                for ind in window_indexes
                    window = windows[ind]
                    t_start = max(start(window), t_start)
                    t_end = min(end_(window), t_end)
                    push!(get!(window_block_time_slices[ind], block, Array{TimeSlice,1}()), TimeSlice(t_start, t_end))
                end
                # Get overlapping initial condition windows
                window_indexes = unique(
                    i
                    for x in t_start:Minute(1):t_end - Minute(1)
                    for i in get(initial_condition_window_map, Minute(x - horizon_init_cond_start).value + 1, ())
                )
                for ind in window_indexes
                    window_initial_condition = initial_condition_windows[ind]
                    t_start = max(start(window_initial_condition), t_start)
                    t_end = min(end_(window_initial_condition), t_end)
                    push!(
                        get!(window_block_time_slices[ind], block_initial_condition, Array{TimeSlice,1}()),
                        TimeSlice(t_start, t_end)
                    )
                end
            end
        end
        window_block_time_slices
    end
end

"""
    generate_time_slice(block_time_slices::Dict{Object,Array{TimeSlice,1}})

Generate and export a convenience functor called `time_slice`, that can be used to retrieve
time slices given by `block_time_slices`. See [@TimeSliceFunctor()](@ref).
"""
function generate_time_slice(block_time_slices)
    # Invert dictionary
    time_slice_blocks = Dict{TimeSlice,Array{Object,1}}()
    for (blk, time_slices) in block_time_slices
        for t in time_slices
            push!(get!(time_slice_blocks, t, Array{Object,1}()), blk)
        end
    end
    # Generate full time slices (ie having block information) and time slice map
    block_full_time_slices = Dict{Object,Array{TimeSlice,1}}()
    block_time_slice_map = Dict{Object,Array{Int64,1}}()
    for (blk, time_slices) in block_time_slices
        temp_block_start = start(first(time_slices))
        temp_block_end = end_(last(time_slices))
        full_time_slices = Array{TimeSlice,1}()
        time_slice_index = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
        for (index, t) in enumerate(time_slices)
            blocks = time_slice_blocks[t]
            push!(full_time_slices, TimeSlice(start(t), end_(t), blocks...))
            # Map time slice
            for x in start(t):Minute(1):end_(t) - Minute(1)
                time_slice_index[Minute(x - temp_block_start).value + 1] = index
            end
        end
        block_full_time_slices[blk] = full_time_slices
        block_time_slice_map[blk] = time_slice_index
    end
    all_time_slices = sort(unique(t for v in values(block_full_time_slices) for t in v))
    # Create and export the function like object
    time_slice = TimeSliceFunctor(all_time_slices, block_full_time_slices)
    to_time_slice = ToTimeSliceFunctor(block_full_time_slices, block_time_slice_map)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        export time_slice
        export to_time_slice
    end
end
