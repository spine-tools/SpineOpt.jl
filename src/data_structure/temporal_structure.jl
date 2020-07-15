#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
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
    block_time_slice_map::Dict{Object,TimeSliceMap}
    function TimeSliceSet(time_slices)
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t in time_slices
            for block in blocks(t)
                push!(get!(block_time_slices, block, []), t)
            end
        end
        block_time_slice_map = Dict(block => TimeSliceMap(time_slices) for (block, time_slices) in block_time_slices)
        # Find eventual gaps in between temporal blocks
        solids = [(first(time_slices), last(time_slices)) for time_slices in values(block_time_slices)]
        sort!(solids)
        gaps = ((from, to) for ((_x, from), (to, _y)) in zip(solids[1:end - 1], solids[2:end]) if from < to)
        # Create bridge time slice map. We need one bridge per gap.
        bridge_time_slice_map = Dict(
            Object("bridge_from_$(from)_to_$(to)") => TimeSliceMap([from, to]) for (from, to) in gaps
        )
        merge!(block_time_slice_map, bridge_time_slice_map)
        new(time_slices, block_time_slices, block_time_slice_map)
    end
end

struct TOverlapsT
    mapping::Dict{TimeSlice,Array{TimeSlice,1}}
end

"""
    (::TimeSliceSet)(;temporal_block=anything, t=anything)

An `Array` of time slices *in the model*.

- `temporal_block` is a temporal block object to filter the result.
- `t` is a `TimeSlice` or collection of `TimeSlice`s *in the model* to filter the result.
"""
(h::TimeSliceSet)(;temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, s) = s
(h::TimeSliceSet)(temporal_block::Object, s) = [t for t in s if temporal_block in t.blocks]
(h::TimeSliceSet)(temporal_blocks::Array{T,1}, s) where T = [t for blk in temporal_blocks for t in h(blk, s)]

"""
    (::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})

A list of time slices that have some time in common with `t` or any time slice in `t`.
"""
function (h::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})
    unique(overlapping_t for s in t for overlapping_t in get(h.mapping, s, ()))
end

"""
    _model_duration_unit()

Fetch the `duration_unit` parameter of the first defined `model`, and defaults to `Minute` if not found.
"""
function _model_duration_unit(instance=first(model()))
    get(Dict(:minute => Minute, :hour => Hour), duration_unit(model=instance, _strict=false), Minute)
end

"""
    _generate_current_window()

A `TimeSlice` spanning the current optimization window from the beginning of the current solve until the beginning of
the next solve or `model_end`, whichever is defined and sooner.
"""
function _generate_current_window()
    instance = first(model())
    model_start_ = model_start(model=instance)
    model_end_ = model_end(model=instance)
    roll_forward_ = roll_forward(model=instance, _strict=false)
    window_start = model_start_
    window_end = (roll_forward_ === nothing) ? model_end_ : min(model_start_ + roll_forward_, model_end_)
    current_window = TimeSlice(window_start, window_end; duration_unit=_model_duration_unit(instance))
    @eval begin
        current_window = $current_window
    end
end

# Adjuster functions, in case blocks specify their own start and end
"""
    _adjuster_start(window_start, window_end, blk_start)

Adjust the `window_start` based on `temporal_blocks`.
"""
_adjusted_start(window_start, ::Nothing) = window_start
_adjusted_start(window_start, blk_start::Union{Period,CompoundPeriod}) = window_start + blk_start
_adjusted_start(window_start, blk_start::DateTime) = max(window_start, blk_start)

"""
    _adjusted_end(window_start, window_end, blk_end)

Adjust the `window_end` based on `temporal_blocks`.
"""
_adjusted_end(window_start, window_end, ::Nothing) = window_end
_adjusted_end(window_start, window_end, blk_end::Union{Period,CompoundPeriod}) = window_start + blk_end
_adjusted_end(window_start, window_end, blk_end::DateTime) = max(window_start, blk_end)

"""
    _time_interval_blocks(window_start, window_end)

A `Dict` mapping 'pre-time_slices' (i.e., (start, end) tuples) to an Array of temporal blocks where found.
"""
function _time_interval_blocks(window_start, window_end)
    blocks_by_time_interval = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    for block in unique(tb for (_n, tb) in node__temporal_block())
        adjusted_start = _adjusted_start(window_start, block_start(temporal_block=block, _strict=false))
        adjusted_end = _adjusted_end(window_start, window_end, block_end(temporal_block=block, _strict=false))
        time_slice_start = adjusted_start
        i = 1
        while time_slice_start < adjusted_end
            duration = resolution(temporal_block=block, i=i)
            if iszero(duration)
                # TODO: Try to move this to a check...
                error("`resolution` of temporal block `$(block)` cannot be zero!")
            end
            time_slice_end = time_slice_start + duration
            if time_slice_end > adjusted_end
                time_slice_end = adjusted_end
                @warn(
                    """
                    the last time slice of temporal block $block has been cut to fit within the optimisation window
                    """
                )
            end
            push!(get!(blocks_by_time_interval, (time_slice_start, time_slice_end), Array{Object,1}()), block)
            time_slice_start = time_slice_end
            i += 1
        end
    end
    blocks_by_time_interval
end

"""
    _window_time_slices(window_start, window_end)

A sorted `Array` of `TimeSlices` in the given window.
"""
function _window_time_slices(window_start, window_end)
    instance = first(model())
    window_time_slices = [
        TimeSlice(t..., blocks...; duration_unit=_model_duration_unit())
        for (t, blocks) in _time_interval_blocks(window_start, window_end)
    ]
    sort!(window_time_slices)
end

"""
    _generate_time_slice()

Create and export a `TimeSliceSet` containing `TimeSlice`s in the current window.

See [@TimeSliceSet()](@ref).
"""
function _generate_time_slice()
    window_start = start(current_window)
    window_end = end_(current_window)
    window_time_slices = _window_time_slices(window_start, window_end)
    time_slice = TimeSliceSet(window_time_slices)
    i = findlast(t -> end_(t) <= window_end, window_time_slices)
    window_span = window_end - window_start
    history_time_slices = [t - window_span for t in window_time_slices[1:i]] 
    history_time_slice = TimeSliceSet(history_time_slices)
    t_history_t = Dict(zip(window_time_slices, history_time_slices))
    @eval begin
        time_slice = $time_slice
        history_time_slice = $history_time_slice
        t_history_t = $t_history_t
        export time_slice
    end
end

"""
    to_time_slice(t::TimeSlice...)

An `Array` of `TimeSlice`s *in the model* overlapping the given `t` (where `t` may not be in model).
"""
function to_time_slice(t::TimeSlice...)
    unique(
        Iterators.flatten(
            t_map(t...)
            for t_set in (time_slice, history_time_slice)
            for t_map in values(t_set.block_time_slice_map)
        )
    )
end

"""
    _generate_time_slice_relationships()

Create and export convenience functions to access time slice relationships.

E.g. `t_in_t`, `t_preceeds_t`, `t_overlaps_t`...
"""
function _generate_time_slice_relationships()
    all_time_slices = Iterators.flatten((history_time_slice(), time_slice()))
    duration_unit = _model_duration_unit()
    t_follows_t_mapping = Dict(t => to_time_slice(t + duration_unit(duration(t))) for t in all_time_slices)
    t_overlaps_t_maping = Dict(t => to_time_slice(t) for t in all_time_slices)
    t_overlaps_t_excl_mapping = Dict(t => setdiff(overlapping_t, t) for (t, overlapping_t) in t_overlaps_t_maping)
    t_before_t_tuples = unique(
        (t_before=t_before, t_after=t_after)
        for (t_before, following) in t_follows_t_mapping
        for t_after in following
        if before(t_before, t_after)
    )
    t_in_t_tuples = unique(
        (t_short=t_short, t_long=t_long)
        for (t_short, overlapping) in t_overlaps_t_maping
        for t_long in overlapping
        if iscontained(t_short, t_long)
    )
    t_in_t_excl_tuples = [(t_short=t1, t_long=t2) for (t1, t2) in t_in_t_tuples if t1 != t2]
    # Create and export the function-like objects
    t_before_t = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_tuples)
    t_in_t = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_tuples)
    t_in_t_excl = RelationshipClass(:t_in_t_excl, [:t_short, :t_long], t_in_t_excl_tuples)
    t_overlaps_t = TOverlapsT(t_overlaps_t_maping)
    t_overlaps_t_excl = TOverlapsT(t_overlaps_t_excl_mapping)
    @eval begin
        t_before_t = $t_before_t
        t_in_t = $t_in_t
        t_in_t_excl = $t_in_t_excl
        t_overlaps_t = $t_overlaps_t
        t_overlaps_t_excl = $t_overlaps_t_excl
        export t_before_t
        export t_in_t
        export t_in_t_excl
        export t_overlaps_t
        export t_overlaps_t_excl
    end
end

"""
    generate_temporal_structure()

Preprocess the temporal structure for SpineOpt from the provided input data.

Runs a number of functions processing different aspects of the temporal structure in sequence.
"""
function generate_temporal_structure()
    _generate_current_window()
    _generate_time_slice()
    _generate_time_slice_relationships()
end

"""
    roll_temporal_structure()

Move the entire temporal structure ahead according to the `roll_forward` parameter.
"""
function roll_temporal_structure()
    instance = first(model())
    end_(current_window) >= model_end(model=instance) && return false
    roll_forward_ = roll_forward(model=instance, _strict=false)
    roll_forward_ === nothing && return false
    roll_forward_ == 0 && return false
    roll!(current_window, roll_forward_)
    roll_time_slice_set!(time_slice, roll_forward_)
    roll_time_slice_set!(history_time_slice, roll_forward_)
    true
end

"""
    roll_time_slice_set!(tss::TimeSliceSet, forward::Union{Period,CompoundPeriod})

Roll a `TimeSliceSet` in time by a period specified by `forward`.
"""
function roll_time_slice_set!(tss::TimeSliceSet, forward::Union{Period,CompoundPeriod})
    roll!.(tss.time_slices, forward)
    for key in keys(tss.block_time_slice_map)
        roll!(tss.block_time_slice_map[key], forward)
    end
    tss
end