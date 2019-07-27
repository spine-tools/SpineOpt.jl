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
    all::Array{TimeSlice,1}
    blocks::Dict{Object,Array{TimeSlice,1}}
end

struct ToTimeSliceFunctor
    blocks::Dict{Object,Array{TimeSlice,1}}
    index::Dict{Object,Array{Int64,1}}
end

"""
    time_slice(;temporal_block=anything, t=anything)

An `Array` of time slices *in the model*.
- `temporal_block` is a temporal block object used to filter the result by.
- `t` is a `TimeSlice` or collection of `TimeSlice`s to intersect the result with.
"""
function (time_slice::TimeSliceFunctor)(;temporal_block=anything, t=anything)
    temporal_block === t === anything && return time_slice.all
    temp_blk = intersect(collect(keys(time_slice.blocks)), Object.(temporal_block))
    # Break `t` into a dictionary keyed by temporal block
    blocks = if t === anything
        Dict{Object,Anything}(blk => anything for blk in temp_blk)
    else
        blocks = Dict{Object,Array{TimeSlice,1}}()
        for t_ in t
            for blk in t_.blocks
                blk in temp_blk || continue
                push!(get!(blocks, blk, Array{TimeSlice,1}()), t_)
            end
        end
        blocks
    end
    sort(unique(t for blk in keys(blocks) for t in intersect(time_slice.blocks[blk], blocks[blk])))
end

"""
    to_time_slice(t::TimeSlice...)

An array of time slices *in the model* that overlap `t`
(where `t` may not be in the model).
"""
function (to_time_slice::ToTimeSliceFunctor)(t::TimeSlice...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, index) in to_time_slice.index
        temp_block_start = start(first(to_time_slice.blocks[blk]))
        temp_block_end = end_(last(to_time_slice.blocks[blk]))
        ranges = []
        for s in t
            s_start = max(temp_block_start, start(s))
            s_end = min(temp_block_end, end_(s))
            s_end <= s_start && continue
            first_ind = index[Minute(s_start - temp_block_start).value + 1]
            last_ind = index[Minute(s_end - temp_block_start).value]
            push!(ranges, first_ind:last_ind)
        end
        isempty(ranges) && continue
        push!(blk_rngs, (blk, union(ranges...)))
    end
    unique(t for (blk, rngs) in blk_rngs for t in to_time_slice.blocks[blk][rngs])
end

"""
    to_time_slice(t::DateTime...)

An array of time slices *in the model* that overlap `t`.
"""
function (to_time_slice::ToTimeSliceFunctor)(t::DateTime...)
    blk_rngs = Array{Tuple{Object,Array{Int64,1}},1}()
    for (blk, index) in to_time_slice.index
        temp_block_start = start(first(to_time_slice.blocks[blk]))
        temp_block_end = end_(last(to_time_slice.blocks[blk]))
        rngs = [
            index[Minute(s - temp_block_start).value + 1]
            for s in t if temp_block_start <= s < temp_block_end
        ]
        push!(blk_rngs, (blk, rngs))
    end
    unique(t for (blk, rngs) in blk_rngs for t in to_time_slice.blocks[blk][rngs])
end

"""
    block_time_slices()

A `Dict` mapping temporal blocks to an `Array` of `TimeSlice`s in that block, sorted.
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
                    "the duration of the last time slice of temporal block $blk has been reduced "
                    * "to respect the specified end time"
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

Like [`block_time_slices()`](@ref) but split among rolling_windows in the given rolling horizon.
"""
function block_time_slices_split(rolling=:default)
    # Compute rolling_windows and rolling_window look-backs if possible
    rolling_windows = Array{TimeSlice,1}()
    rolling_window_initial_conditions = Array{TimeSlice,1}()
    # try
        global horizon_start = start_datetime(rolling=rolling)
        global horizon_initial_condition_start = horizon_start - initial_condition_duration(rolling=rolling, i=1)
        horizon_end = end_datetime(rolling=rolling)
        rolling_window_start = horizon_start
        i = 1
        while rolling_window_start < horizon_end
            rolling_window_dur = rolling_window_duration(rolling=rolling, i=i)
            initial_condition_dur = initial_condition_duration(rolling=rolling, i=i)
            reoptimization_frequ = reoptimization_frequency(rolling=rolling, i=i)
            rolling_window_end = rolling_window_start + rolling_window_dur
            if rolling_window_end > horizon_end
                rolling_window_end = horizon_end
            end
            initial_condition_start = rolling_window_start - initial_condition_dur
            push!(rolling_windows, TimeSlice(rolling_window_start, rolling_window_end))
            push!(rolling_window_initial_conditions, TimeSlice(initial_condition_start, rolling_window_start))
            rolling_window_start += reoptimization_frequ
            i += 1
        end
        horizon_minutes = Minute(horizon_end - horizon_start).value
        # Build map of rolling_windows and look-backs in the entire horizon
        global rolling_window_map = [Array{Int64,1}() for i in 1:horizon_minutes]
        global rolling_window_initial_condition_map = [Array{Int64,1}() for i in 1:horizon_minutes]
        for (rolling_window_index, rolling_window) in enumerate(rolling_windows)
            for x in start(rolling_window):Minute(1):end_(rolling_window) - Minute(1)
                push!(rolling_window_map[Minute(x - horizon_start).value + 1], rolling_window_index)
            end
        end
        for (rolling_window_index, rolling_window_initial_condition) in enumerate(rolling_window_initial_conditions)
            for x in start(rolling_window_initial_condition):Minute(1):end_(rolling_window_initial_condition) - Minute(1)
                push!(rolling_window_initial_condition_map[Minute(x - horizon_initial_condition_start).value + 1], rolling_window_index)
            end
        end
    # catch UndefVarError
        # `rolling_windows` should be empty here
    # end
    if isempty(rolling_windows)
        # No rolling_windows, can't do any split
        [block_time_slices()]
    else
        # Do split
        rolling_window_time_slices = [Dict{Object,Array{TimeSlice,1}}() for i in 1:length(rolling_windows)]
        for (block, time_slices) in block_time_slices()
            # We need a different block for the time slices in the look back zone,
            # since we don't want to 'track' variables here
            # TODO: Fix name ambiguity
            block_initial_condition = Object(Symbol(block.name, "_initial_condition"))
            for t in time_slices
                t_start = start(t)
                t_end = end_(t)
                # Get overlapping rolling_windows
                rolling_window_indexes = unique(
                    i
                    for x in t_start:Minute(1):t_end - Minute(1)
                    for i in get(rolling_window_map, Minute(x - horizon_start).value + 1, ())
                )
                for rolling_window_index in rolling_window_indexes
                    rolling_window = rolling_windows[rolling_window_index]
                    t_start = max(start(rolling_window), t_start)
                    t_end = min(end_(rolling_window), t_end)
                    push!(get!(rolling_window_time_slices[rolling_window_index], block, Array{TimeSlice,1}()), TimeSlice(t_start, t_end))
                end
                # Get overlapping rolling_window look-backs
                rolling_window_indexes = unique(
                    i
                    for x in t_start:Minute(1):t_end - Minute(1)
                    for i in get(rolling_window_initial_condition_map, Minute(x - horizon_initial_condition_start).value + 1, ())
                )
                for rolling_window_index in rolling_window_indexes
                    rolling_window_initial_condition = rolling_window_initial_conditions[rolling_window_index]
                    t_start = max(start(rolling_window_initial_condition), t_start)
                    t_end = min(end_(rolling_window_initial_condition), t_end)
                    push!(
                        get!(rolling_window_time_slices[rolling_window_index], block_initial_condition, Array{TimeSlice,1}()),
                        TimeSlice(t_start, t_end)
                    )
                end
            end
        end
        rolling_window_time_slices
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
    # Generate full time slices (ie having block information) and time slice index
    block_full_time_slices = Dict{Object,Array{TimeSlice,1}}()
    block_time_slice_index = Dict{Object,Array{Int64,1}}()
    for (blk, time_slices) in block_time_slices
        temp_block_start = start(first(time_slices))
        temp_block_end = end_(last(time_slices))
        full_time_slices = Array{TimeSlice,1}()
        time_slice_index = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
        for (index, t) in enumerate(time_slices)
            blocks = time_slice_blocks[t]
            push!(full_time_slices, TimeSlice(start(t), end_(t), blocks...))
            # Index time slice
            for x in start(t):Minute(1):end_(t) - Minute(1)
                time_slice_index[Minute(x - temp_block_start).value + 1] = index
            end
        end
        block_full_time_slices[blk] = full_time_slices
        block_time_slice_index[blk] = time_slice_index
    end
    all_time_slices = sort(unique(t for v in values(block_full_time_slices) for t in v))
    # Create and export the function like object
    time_slice = TimeSliceFunctor(all_time_slices, block_full_time_slices)
    to_time_slice = ToTimeSliceFunctor(block_full_time_slices, block_time_slice_index)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        export time_slice
        export to_time_slice
    end
end
