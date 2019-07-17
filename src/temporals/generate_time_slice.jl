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

A `Dict` mapping temporal blocks to an `Array` of `TimeSlice`s in that block.
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

Like [`block_time_slices()`](@ref) but split among steps in the given rolling horizon.
"""
function block_time_slices_split(rolling=:default)
    # Get steps if any
    steps = Array{TimeSlice,1}()
    try
        horizon_start = start_datetime(rolling=rolling)
        horizon_end = end_datetime(rolling=rolling)
        step_start = horizon_start
        i = 1
        while step_start < horizon_end
            duration = step_duration(rolling=rolling, i=i)
            step_end = step_start + duration
            if step_end > horizon_end
                step_end = horizon_end
            end
            push!(steps, TimeSlice(step_start, step_end))
            step_start = step_end
            i += 1
        end
        steps
    catch UndefVarError
    end
    if isempty(steps)
        # No steps, can't split
        [block_time_slices()]
    else
        # Do the splitting
        result = Dict(step => Dict{Object,Array{TimeSlice,1}}() for step in steps)
        for (block, time_slices) in block_time_slices()
            steps_copy = copy(steps)
            step = popfirst!(steps_copy)
            step_time_slices = result[step][block] = Array{TimeSlice,1}()
            # Move forward to the interesting part
            i = findfirst(end_.(time_slices) .> start(step))
            if i === nothing
                result[step][block]
                continue
            end
            # Adjust start of the first time slice
            if start(time_slices[i]) < start(step)
                time_slices[i] = TimeSlice(start(step), end_(time_slices[i]))
            end
            for t in time_slices[i:end]
                if end_(t) <= end_(step)
                    # time slice well within the step
                    push!(step_time_slices, t)
                else
                    # time slice needs to be split across two steps
                    breakpoint = end_(step)
                    push!(step_time_slices, TimeSlice(start(t), breakpoint))
                    isempty(steps_copy) && break
                    step = popfirst!(steps_copy)
                    step_time_slices = result[step][block] = Array{TimeSlice,1}()
                    push!(step_time_slices, TimeSlice(breakpoint, end_(t)))
                end
            end
        end
        [result[step] for step in steps]
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
