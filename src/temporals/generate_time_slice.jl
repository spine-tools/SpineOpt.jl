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
- `temporal_block` is a temporal block object used to filter the result by.
- `t` is a `TimeSlice` or collection of `TimeSlice`s to filter the result by.
"""
(h::TimeSliceSet)(;temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, s) = intersect(h.time_slices, s)
(h::TimeSliceSet)(temporal_block::Object, s) =
    intersect(h.block_time_slices[temporal_block], (t for t in s if temporal_block in t.blocks))

"""
    to_time_slice(t::TimeSlice...)

An array of time slices *in the model* that overlap `t`
(where `t` may not be in the model).
"""
function (h::ToTimeSlice)(t::TimeSlice...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, time_slice_map) in h.block_time_slice_map
        temp_block_start = start(first(h.block_time_slices[blk]))
        temp_block_end = end_(last(h.block_time_slices[blk]))
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
    unique(t for (blk, rngs) in blk_rngs for t in h.block_time_slices[blk][rngs])
end

"""
    to_time_slice(t::DateTime...)

An array of time slices *in the model* that overlap `t`.
"""
function (h::ToTimeSlice)(t::DateTime...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, time_slice_map) in h.block_time_slice_map
        temp_block_start = start(first(h.block_time_slices[blk]))
        temp_block_end = end_(last(h.block_time_slices[blk]))
        rngs = [
            time_slice_map[Minute(s - temp_block_start).value + 1]
            for s in t if temp_block_start <= s < temp_block_end
        ]
        push!(blk_rngs, (blk, rngs))
    end
    unique(t for (blk, rngs) in blk_rngs for t in h.block_time_slices[blk][rngs])
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
function window_block_time_slices(rolling=nothing)
    windows = TimeSlice[]
    if rolling != nothing
        # Compute `windows` and `initial_condition_windows`
        initial_condition_windows = TimeSlice[]
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
        # Map each minute in the horizon to the indexes of windows defined over that minute.
        # This is used below to allocate time slices to windows
        window_map = [Int64[] for i in 1:Minute(horizon_end - horizon_start).value]
        for (ind, window) in enumerate(windows)
            first_minute = Minute(start(window) - horizon_start).value + 1
            last_minute = Minute(end_(window) - horizon_start).value
            push!.(window_map[first_minute:last_minute], ind)
        end
        # Repeat the above, now for initial condition windows
        init_cond_window_map = [Int64[] for i in 1:Minute(horizon_end - horizon_init_cond_start).value]
        for (ind, initial_condition_window) in enumerate(initial_condition_windows)
            first_minute = Minute(start(initial_condition_window) - horizon_init_cond_start).value + 1
            last_minute = Minute(end_(initial_condition_window) - horizon_init_cond_start).value
            push!.(init_cond_window_map[first_minute:last_minute], ind)
        end
    end
    if isempty(windows)
        # No windows, can't do any split
        [block_time_slices()]
    else
        # Do split. Basically we go through all blocks and time slices and allocate them
        # to the appropriate windows
        window_block_time_slices = [Dict{Object,Array{TimeSlice,1}}() for i in 1:length(windows)]
        for (block, time_slices) in block_time_slices()
            # We need a different block for the time slices in the initial conditions zone,
            # since we don't want to 'track' variables there
            # TODO: Fix name ambiguity
            init_cond_blk = Object(Symbol(block.name, "_initial_condition"))
            for t in time_slices
                # Translate the time slice into minutes since the beginning of the horizon,
                # and then look at the window map we created above to find out the windows where it belongs
                first_minute = max(1, Minute(start(t) - horizon_start).value + 1)
                last_minute = min(length(window_map), Minute(end_(t) - horizon_start).value)
                window_indexes = unique(Iterators.flatten(window_map[first_minute:last_minute]))
                for ind in window_indexes
                    window = windows[ind]
                    # Adjust time slice to fit in the window
                    t_start = max(start(window), start(t))
                    t_end = min(end_(window), end_(t))
                    push!(get!(window_block_time_slices[ind], block, TimeSlice[]), TimeSlice(t_start, t_end))
                end
                # Repeat the above, now for initial condition windows
                first_minute = max(1, Minute(start(t) - horizon_init_cond_start).value + 1)
                last_minute = min(length(init_cond_window_map), Minute(end_(t) - horizon_init_cond_start).value)
                window_indexes = unique(Iterators.flatten(init_cond_window_map[first_minute:last_minute]))
                for ind in window_indexes
                    initial_condition_window = initial_condition_windows[ind]
                    t_start = max(start(initial_condition_window), start(t))
                    t_end = min(end_(initial_condition_window), end_(t))
                    push!(get!(window_block_time_slices[ind], init_cond_blk, TimeSlice[]), TimeSlice(t_start, t_end))
                end
            end
        end
        window_block_time_slices
    end
end

"""
    generate_time_slice(block_time_slices::Dict{Object,Array{TimeSlice,1}})

Generate and export a convenience functor called `time_slice`, that can be used to retrieve
time slices given by `block_time_slices`. See [@TimeSliceSet()](@ref).
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
        time_slice_map = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
        for (ind, t) in enumerate(time_slices)
            blocks = time_slice_blocks[t]
            push!(full_time_slices, TimeSlice(start(t), end_(t), blocks...))
            # Map each minute in the block to the corresponding time slice index (used by `ToTimeSlice`)
            first_minute = Minute(start(t) - temp_block_start).value + 1
            last_minute = Minute(end_(t) - temp_block_start).value
            time_slice_map[first_minute:last_minute] .= ind
        end
        block_full_time_slices[blk] = full_time_slices
        block_time_slice_map[blk] = time_slice_map
    end
    all_time_slices = sort(unique(t for v in values(block_full_time_slices) for t in v))
    # Create and export the function like object
    time_slice = TimeSliceSet(all_time_slices, block_full_time_slices)
    to_time_slice = ToTimeSlice(block_full_time_slices, block_time_slice_map)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        export time_slice
        export to_time_slice
    end
end
