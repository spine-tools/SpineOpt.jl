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
- `temporal_block` is a temporal block object to filter the result.
- `t` is a `TimeSlice` or collection of `TimeSlice`s *in the model* to filter the result.
"""
(h::TimeSliceSet)(;temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, s) = s
(h::TimeSliceSet)(temporal_block::Object, s) = (t for t in s if temporal_block in t.blocks)

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
    rolling_windows()

An iterator over tuples of start and end time for each rolling window.
"""
function rolling_windows()
    instance = first(model())
    m_start = model_start(model=instance)
    m_end = model_end(model=instance)
    m_roll_forward = roll_forward(model=instance, _strict=false)
    m_roll_forward === nothing && return ((m_start, m_end),)
    ticks = m_start:m_roll_forward:m_end
    zip(ticks[1:end - 1], ticks[2:end])
end

# Adjuster functions, in case blocks specify their own start and end
adjusted_start(window_start, window_end, ::Nothing) = window_start
adjusted_start(window_start, window_end, blk_start::Period) = min(window_start + blk_start, window_end)
adjusted_start(window_start, window_end, blk_start::DateTime) = max(window_start, blk_start)

adjusted_end(blk_start, window_end, ::Nothing) = window_end
adjusted_end(blk_start, window_end, blk_end::Period) = min(window_end, blk_start + blk_end)
adjusted_end(blk_start, window_end, blk_end::DateTime) = min(window_end, blk_end)


"""
    time_slices_per_block(window_start, window_end)

A `Dict` mapping temporal blocks to a sorted `Array` of `TimeSlice`s in that block.
"""
function block_time_slices(window_start, window_end)
    d = Dict{Object,Array{TimeSlice,1}}()
    for blk in temporal_block()
        time_slices = Array{TimeSlice,1}()
        blk_spec_start = block_start(temporal_block=blk, _strict=false)
        blk_spec_end = block_end(temporal_block=blk, _strict=false)
        blk_start = adjusted_start(window_start, window_end, blk_spec_start)
        blk_end = adjusted_end(blk_start, window_end, blk_spec_end)
        time_slice_start = blk_start
        i = 1
        while time_slice_start < blk_end
            duration = resolution(temporal_block=blk, i=i)
            time_slice_end = time_slice_start + duration
            if time_slice_end > blk_end
                time_slice_end = blk_end
                @warn(
                    """
                    the last time slice of temporal block $blk has been cut to fit within the optimisation window
                    """
                )
            end
            push!(time_slices, TimeSlice(time_slice_start, time_slice_end))
            time_slice_start = time_slice_end
            i += 1
        end
        d[blk] = time_slices
    end
    d
end

"""
    generate_time_slice(window_start, window_end)

Generate and export a convenience functor called `time_slice`, that can be used to retrieve
time slices in the model between `window_start` and `window_end`. See [@TimeSliceSet()](@ref).
"""
function generate_time_slice(window_start, window_end)
    blk_time_slices = block_time_slices(window_start, window_end)
    # Invert dictionary
    time_slice_blocks = Dict{TimeSlice,Array{Object,1}}()
    for (blk, time_slices) in blk_time_slices
        for t in time_slices
            push!(get!(time_slice_blocks, t, Array{Object,1}()), blk)
        end
    end
    # Generate full time slices (ie having block information) and time slice map
    block_full_time_slices = Dict{Object,Array{TimeSlice,1}}()
    block_time_slice_map = Dict{Object,Array{Int64,1}}()
    instance = first(model())
    d = Dict(:minute => Minute, :hour => Hour)
    dur_unit = get(d, duration_unit(model=instance, _strict=false), Minute)
    for (blk, time_slices) in blk_time_slices
        temp_block_start = start(first(time_slices))
        temp_block_end = end_(last(time_slices))
        full_time_slices = Array{TimeSlice,1}()
        time_slice_map = Array{Int64,1}(undef, Minute(temp_block_end - temp_block_start).value)
        for (ind, t) in enumerate(time_slices)
            blocks = time_slice_blocks[t]
            push!(full_time_slices, TimeSlice(start(t), end_(t), blocks...; duration_unit=dur_unit))
            # Map each minute in the block to the corresponding time slice index (used by `ToTimeSlice`)
            first_minute = Minute(start(t) - temp_block_start).value + 1
            last_minute = Minute(end_(t) - temp_block_start).value
            time_slice_map[first_minute:last_minute] .= ind
        end
        block_full_time_slices[blk] = full_time_slices
        block_time_slice_map[blk] = time_slice_map
    end
    all_time_slices = sort(unique(t for v in values(block_full_time_slices) for t in v))
    # Create and export the function-like objects
    time_slice = TimeSliceSet(all_time_slices, block_full_time_slices)
    to_time_slice = ToTimeSlice(block_full_time_slices, block_time_slice_map)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        export time_slice
        export to_time_slice
    end
end
