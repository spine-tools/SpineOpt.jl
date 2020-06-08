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
    function TimeSliceSet(time_slices)
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t in time_slices
            for block in blocks(t)
                push!(get!(block_time_slices, block, []), t)
            end
        end
        new(time_slices, block_time_slices)
    end
end

struct TOverlapsT
    list::Array{Tuple{TimeSlice,TimeSlice},1}
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
(h::TimeSliceSet)(temporal_blocks::Array{T,1}, s) where T = [t for blk in temporal_blocks for t in h(blk, s)]

"""
    t_overlaps_t()

A list of tuples `(t1, t2)` where `t1` and `t2` have some time in common.
"""
function (h::TOverlapsT)()
    h.list
end

"""
    t_overlaps_t(t_overlap)

A list of time slices that have some time in common with `t_overlap`
(or some time in common with any element in `t_overlap` if it's a list).
"""
function (h::TOverlapsT)(t_overlap)
    unique(t2 for (t1, t2) in h.list if t1 in tuple(t_overlap...))
end

"""
    t_overlaps_t(t1, t2)

A list of time slices which are in `t1` and have some time in common
with any of the time slices in `t2` and vice versa.
"""
function (h::TOverlapsT)(t1, t2)
    unique(Iterators.flatten(filter(t -> t[1] in tuple(t1...) && t[2] in tuple(t2...), h.list)))
end

"""
    rolling_windows()

A tuple of start and end time for the main rolling window.
"""
function _generate_current_window()
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
_adjusted_start(window_start, window_end, ::Nothing) = window_start
_adjusted_start(window_start, window_end, blk_start::Union{Period,CompoundPeriod}) = window_start + blk_start
_adjusted_start(window_start, window_end, blk_start::DateTime) = max(window_start, blk_start)

_adjusted_end(window_start, window_end, ::Nothing) = window_end
_adjusted_end(window_start, window_end, blk_end::Union{Period,CompoundPeriod}) = window_start + blk_end
_adjusted_end(window_start, window_end, blk_end::DateTime) = max(window_start, blk_end)

"""
    _block_time_intervals(window_start, window_end)

A `Dict` mapping temporal blocks to a sorted `Array` of time intervals, i.e., (start, end) tuples.
"""
function _block_time_intervals(window_start, window_end)
    d = Dict{Object,Array{Tuple{DateTime,DateTime},1}}()
    for block in temporal_block()
        time_intervals = Array{Tuple{DateTime,DateTime},1}()
        adjusted_start = _adjusted_start(window_start, window_end, block_start(temporal_block=block, _strict=false))
        adjusted_end = _adjusted_end(window_start, window_end, block_end(temporal_block=block, _strict=false))
        time_slice_start = adjusted_start
        i = 1
        while time_slice_start < adjusted_end
            duration = resolution(temporal_block=block, i=i)
            if iszero(duration)
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
            push!(time_intervals, (time_slice_start, time_slice_end))
            time_slice_start = time_slice_end
            i += 1
        end
        d[block] = time_intervals
    end
    d
end

function _model_duration_unit()
    get(Dict(:minute => Minute, :hour => Hour), duration_unit(model=first(model()), _strict=false), Minute)
end

"""
    _window_time_slices(window_start, window_end)

A sorted `Array` of `TimeSlices` in the given window.
"""
function _window_time_slices(window_start, window_end)
    block_time_intervals = _block_time_intervals(window_start, window_end)
    inv_block_time_intervals = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    for (block, time_intervals) in block_time_intervals
        for t in time_intervals
            push!(get!(inv_block_time_intervals, t, Array{Object,1}()), block)
        end
    end
    instance = first(model())
    a = [TimeSlice(t..., blocks...; duration_unit=_model_duration_unit()) for (t, blocks) in inv_block_time_intervals]
    sort!(a)
end

"""
    _generate_time_slice()

Create and export a `TimeSliceSet` containing `TimeSlice`s in the current window.

See [@TimeSliceSet()](@ref).
"""
function _generate_time_slice()
    window_start = start(current_window)
    window_end = end_(current_window)
    window_span = window_end - window_start
    window_time_slices = _window_time_slices(window_start, window_end)
    time_slice = TimeSliceSet(window_time_slices)
    t_history_t = Dict(t => t - window_span for t in window_time_slices if end_(t) <= window_end)
    all_time_slices = [sort(collect(values(t_history_t))); window_time_slices]
    to_time_slice = TimeSliceMap(all_time_slices)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        t_history_t = $t_history_t
        all_time_slices = $all_time_slices
        export time_slice
        export to_time_slice
    end
end

"""
    _generate_time_slice_relationships()

Create and export convenience functions to access time slice relationships:
`t_in_t`, `t_preceeds_t`, `t_overlaps_t`...
"""
function _generate_time_slice_relationships()
    t_before_t_tuples = []
    t_in_t_tuples = []
    t_overlaps_t_tuples = []
    # NOTE: splitting the loop into two loops as below makes it ~2 times faster
    for (i, t_i) in enumerate(all_time_slices)
        found = false
        for t_j in all_time_slices[i:end]
            if before(t_i, t_j)
                found = true
                push!(t_before_t_tuples, (t_before=t_i, t_after=t_j))
            elseif found
                break
            end
        end
    end
    for t_i in all_time_slices
        found_in = false
        break_in = false
        found_overlaps = false
        break_overlaps = false
        for t_j in all_time_slices
            if iscontained(t_i, t_j)
                found_in = true
                push!(t_in_t_tuples, (t_short=t_i, t_long=t_j))
            elseif found_in
                break_in = true
            end
            if overlaps(t_i, t_j)
                found_overlaps = true
                push!(t_overlaps_t_tuples, tuple(t_i, t_j))
            elseif found_overlaps
                break_overlaps = true
            end
            if break_in && break_overlaps
                break
            end
        end
    end
    unique!(t_in_t_tuples)
    unique!(t_overlaps_t_tuples)
    t_in_t_excl_tuples = [(t_short=t1, t_long=t2) for (t1, t2) in t_in_t_tuples if t1 != t2]
    t_overlaps_t_excl_tuples = [(t1, t2) for (t1, t2) in t_overlaps_t_tuples if t1 != t2]
    # Create function-like objects
    t_before_t = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_tuples)
    t_in_t = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_tuples)
    t_in_t_excl = RelationshipClass(:t_in_t_excl, [:t_short, :t_long], t_in_t_excl_tuples)
    t_overlaps_t = TOverlapsT(t_overlaps_t_tuples)
    t_overlaps_t_excl = TOverlapsT(t_overlaps_t_excl_tuples)
    # Export the function-like objects
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

function generate_temporal_structure()
    _generate_current_window()
    _generate_time_slice()
    _generate_time_slice_relationships()
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

# TODO: Currently, the temporal structure seems to be generated for all defined `temporal_blocks` in the database, 
# regardless of whether they actually appear in the model via the `node__temporal_block` relationship.