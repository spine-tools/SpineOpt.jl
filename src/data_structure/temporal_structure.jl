#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

struct TimeSliceSet
    time_slices::Array{TimeSlice,1}
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    gaps::Array{TimeSlice,1}
    bridges::Array{TimeSlice,1}
    function TimeSliceSet(time_slices, dur_unit; bridge_gaps=true)
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t in time_slices
            for block in blocks(t)
                push!(get!(block_time_slices, block, []), t)
            end
        end
        # Bridge gaps in between temporal blocks
        solids = [
            (start(t_first), end_(t_last))
            for (t_first, t_last) in (
                (first(time_slices), last(time_slices)) for time_slices in values(block_time_slices)
            )
            if !any(has_free_start(temporal_block=blk) for blk in blocks(t_first))
        ]
        gaps = if isempty(solids)
            []
        else
            gap_dicts = [Dict(:start => minimum(first.(solids)), :end => maximum(last.(solids)))]
            for (s_start, s_end) in solids
                new_gap_d = nothing
                for gap_d in gap_dicts
                    if gap_d[:start] <= s_start && s_end <= gap_d[:end]
                        # Split
                        new_gap_d = Dict(:start => s_end, :end => gap_d[:end])
                        gap_d[:end] = s_start
                    elseif s_start <= gap_d[:start] <= s_end
                        # Adjust start
                        gap_d[:start] = s_end
                    elseif s_start <= gap_d[:end] <= s_end
                        # Adjust end
                        gap_d[:end] = s_start
                    end
                end
                new_gap_d === nothing || push!(gap_dicts, new_gap_d)
            end
            filter!(unique!(gap_dicts)) do gap_d
                gap_d[:start] < gap_d[:end]
            end
            sort!([TimeSlice(gap_d[:start], gap_d[:end]; duration_unit=dur_unit) for gap_d in gap_dicts])
        end
        bridges = [first(t for t in time_slices if start(t) == end_(gap)) for gap in gaps]
        new(time_slices, block_time_slices, gaps, bridges)
    end
end

struct TOverlapsT
    overlapping_time_slices::Dict{TimeSlice,Vector{TimeSlice}}
end

(h::TimeSliceSet)(; temporal_block=anything, t=anything)::Vector{TimeSlice} = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = get(h.block_time_slices, temporal_block, [])
(h::TimeSliceSet)(::Anything, t) = t
(h::TimeSliceSet)(temporal_block::Object, t) = [s for s in t if temporal_block in blocks(s)]
(h::TimeSliceSet)(temporal_blocks::Array{T,1}, t) where {T} = unique(s for blk in temporal_blocks for s in h(blk, t))

"""
    (::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})

An array of time slices that overlap with `t` or with any time slice in `t`.
"""
function (h::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})
    unique(overlapping_t for s in t for overlapping_t in get(h.overlapping_time_slices, s, ()))
end

"""
    _model_duration_unit(instance::Object)

Fetch the `duration_unit` parameter of the first defined `model`, and defaults to `Minute` if not found.
"""
_model_duration_unit(m::Model) = _model_duration_unit(m.ext[:spineopt].instance)
function _model_duration_unit(instance::Object)
    get(Dict(:minute => Minute, :hour => Hour), duration_unit(model=instance, _strict=false), Minute)
end

function _model_window_duration(m)
    instance = m.ext[:spineopt].instance
    m_start = model_start(model=instance)
    m_end = model_end(model=instance)
    m_duration = m_end - m_start
    w_duration = window_duration(model=instance, _strict=false)
    if w_duration === nothing
        w_duration = roll_forward(model=instance, i=1, _strict=false)
    end
    if w_duration === nothing || m_start + w_duration > m_end
        m_duration
    else
        w_duration
    end
end

# Adjuster functions, in case blocks specify their own start and end
"""
    _adjuster_start(window_start, window_end, blk_start)

The adjusted start of a `temporal_block`.
"""
_adjusted_start(w_start::DateTime, _blk_start::Nothing) = w_start
_adjusted_start(w_start::DateTime, blk_start::Union{Period,CompoundPeriod}) = w_start + blk_start
_adjusted_start(w_start::DateTime, blk_start::DateTime) = max(w_start, blk_start)

"""
    _adjusted_end(window_start, window_end, blk_end)

The adjusted end of a `temporal_block`.
"""
_adjusted_end(_w_start::DateTime, w_end::DateTime, _blk_end::Nothing) = w_end
_adjusted_end(w_start::DateTime, _w_end::DateTime, blk_end::Union{Period,CompoundPeriod}) = w_start + blk_end
_adjusted_end(w_start::DateTime, _w_end::DateTime, blk_end::DateTime) = max(w_start, blk_end)

"""
    _blocks_by_representative_interval(m::Model, window_start, window_end)

A `Dict` mapping temporal block `Object`s to (start, end) tuples representing their end-points.
"""

function _start_and_end_by_block(m::Model, window_start, window_end)
    model_blocks = members(temporal_block())
    isempty(model_blocks) && error("model $(_model_name(m)) doesn't have any temporal_blocks")
    window_very_end = maximum(
        _adjusted_end(window_start, window_end, block_end(temporal_block=tb, _strict=false)) for tb in model_blocks
    )
    start_and_end_by_block = Dict(
        blk => (
            _adjusted_start(window_start, block_start(temporal_block=blk, _strict=false)),
            _adjusted_end(window_start, window_very_end, block_end(temporal_block=blk, _strict=false)),
        )
        for blk in members(temporal_block())
    )
end

function _blocks_and_mapping_by_interval(start_and_end_by_block)
    blocks_and_mapping_by_interval = Dict()
    for blk in members(temporal_block(representative_periods_mapping=nothing))
        blk_start, blk_end = start_and_end_by_block[blk]
        t_start = blk_start
        i = 1
        while t_start < blk_end
            res = resolution(temporal_block=blk, i=i, s=t_start, _strict=false)
            res !== nothing || break
            if iszero(res)
                # TODO: Try to move this to a check...
                error("`resolution` of temporal block `$blk` cannot be zero!")
            end
            t_end = t_start + res
            if t_end > blk_end
                t_end = blk_end
                @info "the last time slice of temporal block $blk has been cut to fit within the block"
            end
            blocks, _mapping = get!(blocks_and_mapping_by_interval, (t_start, t_end), (Set(), nothing))
            push!(blocks, blk)
            t_start = t_end
            i += 1
        end
    end
    blocks_and_mapping_by_interval
end

function _add_blocks_and_mapping_for_represented_intervals!(blocks_and_mapping_by_interval, start_and_end_by_block)
    blocks_and_mapping_by_represented_interval = Dict()
    representative_blk_by_index = Dict()
    for blk in indices(representative_period_index)
        index = round(Int, representative_period_index(temporal_block=blk))
        existing_blk = get(representative_blk_by_index, index, nothing)
        if existing_blk !== nothing
            error(
                "representative blocks `$blk` and `$existing_blk` cannot have the same index `$index` \
                - each representative block must have a unique `representative_period_index`"
            )
        end
        representative_blk_by_index[index] = blk
    end
    for represented_blk in indices(representative_periods_mapping)
        blk_start, blk_end = start_and_end_by_block[represented_blk]
        mapping = representative_periods_mapping(temporal_block=represented_blk)
        representative_blk_to_coef_by_start = Dict(
            t_start => _representative_block_to_coefficient(repr_comb, representative_blk_by_index)
            for (t_start, repr_comb) in mapping
        )
        mapping_blocks = unique(
            blk for blk_to_coef in values(representative_blk_to_coef_by_start) for (blk, _coeff) in blk_to_coef
        )
        represented_t_starts = sort!(collect(keys(mapping)))
        filter!(represented_t_starts) do t_start
            t_start < blk_end
        end
        represented_t_ends = [represented_t_starts[2:end]; blk_end]
        for (represented_t_start, represented_t_end) in zip(represented_t_starts, represented_t_ends)
            represented_interval = (represented_t_start, represented_t_end)
            representative_blk_to_coef = representative_blk_to_coef_by_start[represented_t_start]
            invalid_blks = setdiff(keys(representative_blk_to_coef), members(temporal_block()))
            if !isempty(invalid_blks)
                error("$represented_interval from '$represented_blk' is mapped to unknown block(s) $invalid_blks")
            end
            coefs_sum = sum(values(representative_blk_to_coef))
            if !isapprox(coefs_sum, 1)
                error(
                    "sum of coefficients for $represented_interval from '$represented_blk' must be 1 - not $coefs_sum"
                )
            end
            # Make sure no represented interval is overlapping a representative interval.
            # If that's the case then add its block to each of the overlapping intervals.
            # This is so representative intervals have all the blocks they need.
            overlapping_representative_intervals = filter(keys(blocks_and_mapping_by_interval)) do interval
                t_start, t_end = interval
                blocks, _mapping = blocks_and_mapping_by_interval[interval]
                (
                    !isdisjoint(mapping_blocks, blocks)
                    && t_end > represented_t_start && t_start < represented_t_end
                )
            end
            if !isempty(overlapping_representative_intervals)
                for interval in overlapping_representative_intervals
                    blocks, _mapping = blocks_and_mapping_by_interval[interval]
                    push!(blocks, represented_blk)
                end
                continue
            end
            existing = get(blocks_and_mapping_by_represented_interval, represented_interval, nothing)
            if existing !== nothing
                blocks, _mapping = existing
                existing_represented_blk = only(blocks)
                error("cannot map $represented_interval from '$represented_blk' \
                    because it already belongs in another represented block $existing_represented_blk",
                )
            end
            blocks_and_mapping_by_represented_interval[represented_interval] = (
                Set(represented_blk), representative_blk_to_coef
            )
        end
    end
    merge!(blocks_and_mapping_by_interval, blocks_and_mapping_by_represented_interval)
end

function _representative_block_to_coefficient(representative_combination::Symbol, _representative_blk_by_index)
    Dict(temporal_block(representative_combination) => 1)
end
function _representative_block_to_coefficient(representative_combination::Array, representative_blk_by_index)
    invalid_indexes = setdiff(keys(representative_combination), keys(representative_blk_by_index))
    if !isempty(invalid_indexes)
        error("there's no representative temporal block(s) with indexes $invalid_indexes") 
    end
    Dict(representative_blk_by_index[k] => coef for (k, coef) in enumerate(representative_combination) if !iszero(coef))
end

function _add_padding_interval!(blocks_and_mapping_by_interval, window_end)
    intervals = collect(keys(blocks_and_mapping_by_interval))
    last_i = intervals[argmax(last.(intervals))]
    temp_struct_end = last(last_i)
    if temp_struct_end < window_end
        padding_interval = (temp_struct_end, window_end)
        blocks, _mapping = get!(blocks_and_mapping_by_interval, padding_interval, (Set(), nothing))
        union!(blocks, blocks_and_mapping_by_interval[last_i])
        @info string(
            "an artificial time slice $padding_interval has been added to blocks $blocks, ",
            "so that the temporal structure fills the optimisation window ",
        )
    end
end

"""
    _required_history_duration(m::Model)

The required length of the included history based on parameter values that impose delays as a `Dates.Period`.
"""
function _required_history_duration(m)
    lookback_params = (
        min_up_time,
        min_down_time,
        scheduled_outage_duration,
        connection_flow_delay,
        unit_investment_tech_lifetime,
        connection_investment_tech_lifetime,
        storage_investment_tech_lifetime,
    )
    max_vals = (maximum_parameter_value(p) for p in lookback_params)
    init = _model_duration_unit(m)(1)  # Dynamics always require at least 1 duration unit of history
    reduce(max, (val for val in max_vals if val !== nothing); init=init)
end

function _intervals_by_history_interval(blocks_and_mapping_by_interval, m, window_start, window_end)
    intervals_by_history_interval = Dict()
    required_history_duration = _required_history_duration(m)
    for ((t_start, t_end), (blocks, _mapping)) in blocks_and_mapping_by_interval
        subwindows = [blk for blk in blocks if has_free_start(temporal_block=blk)]
        subwindow_start, subwindow_end = if length(subwindows) > 1
            error("interval $((t_start, t_end)) is in more than one block with free start: $subwindows")
        elseif length(subwindows) == 1
            subwindow = only(subwindows)
            subwindow_start = _adjusted_start(window_start, block_start(temporal_block=subwindow, _strict=false))
            subwindow_end = _adjusted_end(window_start, window_end, block_end(temporal_block=subwindow, _strict=false))
            subwindow_start, subwindow_end
        else
            window_start, window_end
        end
        h_start, h_end = t_start, min(t_end, subwindow_end)
        h_start < h_end || continue
        history_start = subwindow_start - required_history_duration
        subwindow_duration = subwindow_end - subwindow_start
        while true
            h_start -= subwindow_duration
            h_end -= subwindow_duration
            h_end > history_start || break
            push!(get!(intervals_by_history_interval, (h_start, h_end), Set()), (t_start, t_end))
        end
    end
    intervals_by_history_interval
end

function _history_time_slices(m, intervals_by_history_interval, time_slice_by_interval)
    # Compute mapping from history interval to history time slice
    history_time_slice_by_interval = Dict(
        (t_start, t_end) => TimeSlice(
            t_start,
            t_end,
            unique(blk for i in intervals for blk in blocks(time_slice_by_interval[i]))...;
            duration_unit=_model_duration_unit(m),
        )
        for ((t_start, t_end), intervals) in intervals_by_history_interval
    )
    # Collect all history time slices
    history_time_slices = sort!(collect(values(history_time_slice_by_interval)))
    # Compute mapping from window time slice to corresponding history time slice
    # Note that more than one window time slice can map to the same history time slice
    t_history_t = Dict(
        time_slice_by_interval[interval] => history_time_slice_by_interval[h_interval]
        for (h_interval, intervals) in intervals_by_history_interval
        for interval in intervals
    )
    history_time_slices, t_history_t
end

"""
    _generate_time_slice!(m::Model)

Create a `TimeSliceSet` containing `TimeSlice`s in the current window.

See [@TimeSliceSet()](@ref).
"""
function _generate_time_slice!(m::Model)
    window = current_window(m)
    window_start = start(window)
    window_end = end_(window)
    start_and_end_by_block = _start_and_end_by_block(m, window_start, window_end)
    blocks_and_mapping_by_interval = _blocks_and_mapping_by_interval(start_and_end_by_block)
    _add_blocks_and_mapping_for_represented_intervals!(blocks_and_mapping_by_interval, start_and_end_by_block)
    _add_padding_interval!(blocks_and_mapping_by_interval, window_end)
    intervals_by_history_interval = _intervals_by_history_interval(
        blocks_and_mapping_by_interval, m, window_start, window_end
    )
    time_slice_by_interval = Dict(
        interval => TimeSlice(interval..., blocks...; duration_unit=_model_duration_unit(m))
        for (interval, (blocks, _mapping)) in blocks_and_mapping_by_interval
    )
    window_time_slices = sort!(collect(values(time_slice_by_interval)))
    m.ext[:spineopt].temporal_structure[:representative_block_coefficients] = Dict(
        time_slice_by_interval[interval] => mapping
        for (interval, (_blocks, mapping)) in blocks_and_mapping_by_interval
        if mapping !== nothing
    )
    history_time_slices, t_history_t = _history_time_slices(m, intervals_by_history_interval, time_slice_by_interval)
    dur_unit = _model_duration_unit(m)
    m.ext[:spineopt].temporal_structure[:time_slice] = TimeSliceSet(window_time_slices, dur_unit)
    m.ext[:spineopt].temporal_structure[:history_time_slice] = TimeSliceSet(
        history_time_slices, dur_unit; bridge_gaps=false
    )
    m.ext[:spineopt].temporal_structure[:t_history_t] = t_history_t
end

struct _AnnotatedTimeSlice
    t::TimeSlice
    is_history::Bool
end

"""
    _generate_time_slice_relationships()

E.g. `t_in_t`, `t_before_t`, `t_overlaps_t`...
"""
function _generate_time_slice_relationships!(m::Model)
    annotated_time_slices = _annotated_time_slice(m)
    succeeding_annotated_time_slices = Dict(
        x => _to_annotated_time_slice(m; t=TimeSlice(end_(x.t), end_(x.t) + Minute(1)))
        for x in annotated_time_slices
    )
    overlapping_annotated_time_slices = Dict(x => _to_annotated_time_slice(m; t=x.t) for x in annotated_time_slices)
    t_before_t_tuples = unique(
        (x_before.t, x_after.t)
        for (x_before, succeeding) in succeeding_annotated_time_slices
        for x_after in succeeding
        if end_(x_before.t) <= start(x_after.t)
        && _check_affinity(x_before, x_after)
    )
    t_in_t_tuples = unique(
        (x_short.t, x_long.t)
        for (x_short, overlapping) in overlapping_annotated_time_slices
        for x_long in overlapping
        if iscontained(x_short.t, x_long.t)
        && _check_affinity(x_short, x_long)
    )
    t_in_t_excl_tuples = [(t_short, t_long) for (t_short, t_long) in t_in_t_tuples if t_short != t_long]
    t_to_overlapping_t = Dict(
        x1.t => [x2.t for x2 in overlapping if _check_affinity(x1, x2)]
        for (x1, overlapping) in overlapping_annotated_time_slices
    )
    # Create the function-like objects
    temp_struct = m.ext[:spineopt].temporal_structure
    temp_struct[:t_before_t] = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_tuples)
    temp_struct[:t_in_t] = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_tuples)
    temp_struct[:t_in_t_excl] = RelationshipClass(:t_in_t_excl, [:t_short, :t_long], t_in_t_excl_tuples)
    temp_struct[:t_overlaps_t] = TOverlapsT(t_to_overlapping_t)
end

"""
An iterator over annotated time slices in the model
"""
function _annotated_time_slice(m)
    _flatten_annotated(history_time_slice(m), time_slice(m))
end

"""
An iterator over annotated time slices in the model that overlap the given t (which may not be in the model)
"""
function _to_annotated_time_slice(m; t::TimeSlice)
    _flatten_annotated(_to_history_time_slice(m; t), _to_window_time_slice(m; t))
end

function _flatten_annotated(history, window)
    history = (_AnnotatedTimeSlice(t, true) for t in history)
    window = (_AnnotatedTimeSlice(t, false) for t in window)
    Iterators.flatten((history, window))
end

"""
Check if two (annotated) time-slices can be part of a relationship in the context of blocks with free-start.
The rule is, the history of a block with free start should only be related to that same block, not to any other.
So, if one of the time slices belongs to the history of a block with free start,
and the other does not belong to that same block, then return false.
Otherwise return true.
"""
function _check_affinity(x1::_AnnotatedTimeSlice, x2::_AnnotatedTimeSlice)
    _do_check_affinity(x1, x2) && _do_check_affinity(x2, x1)
end

function _do_check_affinity(x1, x2)
    x1.is_history || return true
    t1_blocks = [blk for blk in blocks(x1.t) if has_free_start(temporal_block=blk)]
    isempty(t1_blocks) && return true
    !isdisjoint(t1_blocks, blocks(x2.t))
end

function _generate_as_number_or_call!(m)
    temp_struct = m.ext[:spineopt].temporal_structure
    algo = model_algorithm(model=m.ext[:spineopt].instance)
    temp_struct[:as_number_or_call] = if (
        needs_auto_updating(Val(algo))
        || temp_struct[:window_count] > 1
        || _is_benders_subproblem(m)
        || (_is_child_stage(m) && !_is_benders_master(m))
    )
        as_call
    else
        as_number
    end
end

function _is_child_stage(m)
    st = m.ext[:spineopt].stage
    parent_stages = if st === nothing
        setdiff(stage(), stage__child_stage(stage2=anything))
    else
        stage__child_stage(stage2=st)
    end
    !isempty(parent_stages)
end


"""
Find indices in `source` that overlap `t` and return values for those indices in `target`.
Used by `to_time_slice`.
"""
function _to_time_slice(target::Array{TimeSlice,1}, source::Array{TimeSlice,1}, t::TimeSlice)
    isempty(source) && return []
    (start(t) < end_(source[end]) && end_(t) > start(source[1])) || return []
    a = searchsortedfirst(source, start(t); lt=(x, y) -> end_(x) <= y)
    b = searchsortedfirst(source, end_(t); lt=(x, y) -> start(x) < y) - 1
    target[a:b]
end
_to_time_slice(time_slices::Array{TimeSlice,1}, t::TimeSlice) = _to_time_slice(time_slices, time_slices, t)

"""
    _roll_time_slice_set!(t_set::TimeSliceSet, forward::Union{Period,CompoundPeriod})

Roll a `TimeSliceSet` in time by a period specified by `forward`.
"""
function _roll_time_slice_set!(t_set::TimeSliceSet, forward::Union{Period,CompoundPeriod})
    updates = collect(_roll_many!(t_set.time_slices, forward))
    append!(updates, _roll_many!(values(t_set.gaps), forward))
    append!(updates, _roll_many!(values(t_set.bridges), forward))
    updates
end

function _roll_many!(t_iter, forward)
    (upd for t in t_iter for upd in roll!(t, forward; return_updates=true))
end

function _time_slice_set_collect_updates(t_set::TimeSliceSet)
    updates = collect(_collect_updates_many(t_set.time_slices))
    append!(updates, _collect_updates_many(values(t_set.gaps)))
    append!(updates, _collect_updates_many(values(t_set.bridges)))
    updates
end

function _collect_updates_many(t_iter)
    (upd for t in t_iter for upd in collect_updates(t))
end

function generate_time_slice!(m::Model)
    _generate_as_number_or_call!(m)
    _generate_time_slice!(m)
    _generate_time_slice_relationships!(m)
end

"""
    _generate_current_window!(m::Model)

Generate the current window TimeSlice for given model.
"""
function _generate_current_window!(m::Model)
    w_start = model_start(model=m.ext[:spineopt].instance)
    w_end = w_start + _model_window_duration(m)
    m.ext[:spineopt].temporal_structure[:current_window] = TimeSlice(
        w_start, w_end; duration_unit=_model_duration_unit(m)
    )
end

function _generate_windows_and_window_count!(m::Model)
    w_start = model_start(model=m.ext[:spineopt].instance)
    w_duration = _model_window_duration(m)
    w_end = w_start + w_duration
    m.ext[:spineopt].temporal_structure[:windows] = windows = []
    push!(windows, TimeSlice(w_start, w_end; duration_unit=_model_duration_unit(m)))
    i = 1
    while true
        rf = roll_forward(model=m.ext[:spineopt].instance, i=i, _strict=false)
        (rf in (nothing, Minute(0)) || w_end >= model_end(model=m.ext[:spineopt].instance)) && break
        w_start += rf
        w_start >= model_end(model=m.ext[:spineopt].instance) && break
        w_end += rf
        push!(windows, TimeSlice(w_start, w_end; duration_unit=_model_duration_unit(m)))
        i += 1
    end
    m.ext[:spineopt].temporal_structure[:window_count] = i
end

"""
    generate_temporal_structure!(m)

Create the temporal structure for the given SpineOpt model.
After this, you can call the following functions to query the generated structure:
- `time_slice`
- `t_before_t`
- `t_in_t`
- `t_in_t_excl`
- `t_overlaps_t`
- `to_time_slice`
- `current_window`
"""
function generate_temporal_structure!(m::Model)
    _generate_current_window!(m)
    _generate_windows_and_window_count!(m)
    generate_time_slice!(m)
end

function _generate_master_window!(m_mp::Model)
    mp_start = model_start(model=m_mp.ext[:spineopt].instance)
    mp_end = model_end(model=m_mp.ext[:spineopt].instance)
    m_mp.ext[:spineopt].temporal_structure[:current_window] = current_window = TimeSlice(
        mp_start, mp_end, duration_unit=_model_duration_unit(m_mp)
    )
    m_mp.ext[:spineopt].temporal_structure[:windows] = [current_window]
    m_mp.ext[:spineopt].temporal_structure[:window_count] = 1
end

"""
    generate_master_temporal_structure!(m_mp)

Create the Benders master problem temporal structure for given model.
"""
function generate_master_temporal_structure!(m_mp::Model)
    _generate_master_window!(m_mp)
    generate_time_slice!(m_mp)
    m_mp.ext[:spineopt].temporal_structure[:representative_block_coefficients] = Dict()
end

"""
    roll_temporal_structure!(m[, window_number=1]; rev=false)

Roll the temporal structure of given SpineOpt model forward a period of time
equal to the value of the `roll_forward` parameter.
If `roll_forward` is an array, then `window_number` can be given either as an `Integer` or a `UnitRange`
indicating the position or successive positions in that array.

If `rev` is `true`, then the structure is rolled backwards instead of forward.
"""
function roll_temporal_structure!(m::Model, i::Integer=1; rev=false)
    rf = roll_forward(model=m.ext[:spineopt].instance, i=i, _strict=false)
    _do_roll_temporal_structure!(m, rf, rev)
end
function roll_temporal_structure!(m::Model, rng::UnitRange{T}; rev=false) where T<:Integer
    rfs = [roll_forward(model=m.ext[:spineopt].instance, i=i, _strict=false) for i in rng]
    filter!(!isnothing, rfs)
    rf = sum(rfs; init=Minute(0))
    _do_roll_temporal_structure!(m, rf, rev)
end

function _do_roll_temporal_structure!(m::Model, rf, rev)
    rf in (nothing, Minute(0)) && return false
    rf = rev ? -rf : rf
    temp_struct = m.ext[:spineopt].temporal_structure
    current_window = temp_struct[:current_window]
    !rev && any(
        x >= model_end(model=m.ext[:spineopt].instance) for x in (end_(current_window), start(current_window) + rf)
    ) && return false
    updates = roll!(current_window, rf; return_updates=true)
    append!(updates, _roll_time_slice_set!(temp_struct[:time_slice], rf))
    append!(updates, _roll_time_slice_set!(temp_struct[:history_time_slice], rf))
    unique!(updates)
    _call_many(updates)
    true
end

"""
    rewind_temporal_structure!(m)

Rewind the temporal structure of given SpineOpt model back to the first window.
"""
function rewind_temporal_structure!(m::Model)
    temp_struct = m.ext[:spineopt].temporal_structure
    roll_count = temp_struct[:window_count] - 1
    if roll_count > 0
        roll_temporal_structure!(m, 1:roll_count; rev=true)
        _update_variable_names!(m)
        _update_constraint_names!(m)
    else
        updates = collect_updates(temp_struct[:current_window])
        append!(updates, _time_slice_set_collect_updates(temp_struct[:time_slice]))
        append!(updates, _time_slice_set_collect_updates(temp_struct[:history_time_slice]))
        unique!(updates)
        _call_many(updates)
    end
end

function _call_many(updates)
    _do_call.(updates)
end

function _do_call(upd)
    upd()
end

"""
    to_time_slice(m; t)

An `Array` of `TimeSlice`s in model `m` overlapping the given `TimeSlice` (where `t` may not be in `m`).
"""
function to_time_slice(m::Model; t::TimeSlice)
    vcat(_to_history_time_slice(m; t), _to_window_time_slice(m; t))
end

function _to_history_time_slice(m::Model; t::TimeSlice)
    t_set = m.ext[:spineopt].temporal_structure[:history_time_slice]
    _to_time_slice_from_set(t_set; t)
end

function _to_window_time_slice(m::Model; t::TimeSlice)
    t_set = m.ext[:spineopt].temporal_structure[:time_slice]
    _to_time_slice_from_set(t_set; t)
end

function _to_time_slice_from_set(t_set; t::TimeSlice)
    in_blocks = (s for time_slices in values(t_set.block_time_slices) for s in _to_time_slice(time_slices, t))
    in_gaps = if isempty(indices(representative_periods_mapping))
        _to_time_slice(t_set.bridges, t_set.gaps, t)
    else
        ()
    end
    unique(Iterators.flatten((in_blocks, in_gaps)))
end

"""
    current_window(m)

A `TimeSlice` corresponding to the current window of given model.
"""
current_window(m::Model) = m.ext[:spineopt].temporal_structure[:current_window]

window_count(m::Model) = m.ext[:spineopt].temporal_structure[:window_count]

"""
    time_slice(m; temporal_block=anything, t=anything)

An `Array` of `TimeSlice`s in model `m`.

 # Arguments
  - `temporal_block::Union{Object,Vector{Object}}`: only return `TimeSlice`s in these blocks.
  - `t::Union{TimeSlice,Vector{TimeSlice}}`: only return `TimeSlice`s that are also in this collection.
"""
time_slice(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:time_slice](; kwargs...)

history_time_slice(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:history_time_slice](; kwargs...)

t_history_t(m::Model; t::TimeSlice) = get(m.ext[:spineopt].temporal_structure[:t_history_t], t, nothing)

"""
    t_before_t(m; t_before=anything, t_after=anything)

An `Array` where each element is a `Tuple` of two *consecutive* `TimeSlice`s in model `m`, i.e.,
the second starting when the first ends.

 # Arguments
  - `t_before`: if given, return an `Array` of `TimeSlice`s that start when `t_before` ends.
  - `t_after`: if given, return an `Array` of `TimeSlice`s that end when `t_after` starts.
"""
function t_before_t(m::Model; kwargs...)
    _with_model_env(m) do
        m.ext[:spineopt].temporal_structure[:t_before_t](; kwargs...)
    end
end

"""
    t_in_t(m; t_short=anything, t_long=anything)

An `Array` where each element is a `Tuple` of two `TimeSlice`s in model `m`,
the second containing the first.

 # Keyword arguments
  - `t_short`: if given, return an `Array` of `TimeSlice`s that contain `t_short`.
  - `t_long`: if given, return an `Array` of `TimeSlice`s that are contained in `t_long`.
"""
function t_in_t(m::Model; kwargs...)
    _with_model_env(m) do
        m.ext[:spineopt].temporal_structure[:t_in_t](; kwargs...)
    end
end

"""
    t_in_t_excl(m; t_short=anything, t_long=anything)

Same as [t_in_t](@ref) but exclude tuples of the same `TimeSlice`.

 # Keyword arguments
  - `t_short`: if given, return an `Array` of `TimeSlice`s that contain `t_short` (other than `t_short` itself).
  - `t_long`: if given, return an `Array` of `TimeSlice`s that are contained in `t_long` (other than `t_long` itself).
"""
function t_in_t_excl(m::Model; kwargs...)
    _with_model_env(m) do
        m.ext[:spineopt].temporal_structure[:t_in_t_excl](; kwargs...)
    end
end

"""
    t_overlaps_t(m; t)

An `Array` of `TimeSlice`s in model `m` that overlap the given `t`, where `t` *must* be in `m`.
"""
t_overlaps_t(m::Model; t::TimeSlice) = m.ext[:spineopt].temporal_structure[:t_overlaps_t](t)

function representative_block_coefficients(m, t)
    get(m.ext[:spineopt].temporal_structure[:representative_block_coefficients], t, Dict())
end

function _repr_t_coefs(m, t)
    blk_coef = representative_block_coefficients(m, t)
    isempty(blk_coef) && return Dict(t => 1)
    Dict(first(time_slice(m; temporal_block=blk)) => coef for (blk, coef) in blk_coef)
end

function _is_representative(t)
    any(representative_periods_mapping(temporal_block=blk) === nothing for blk in blocks(t))
end

function represented_time_slices(m)
    keys(m.ext[:spineopt].temporal_structure[:representative_block_coefficients])
end

function output_time_slice(m::Model; output::Object)
    get(m.ext[:spineopt].temporal_structure[:output_time_slice], output, nothing)
end

function dynamic_time_indices(m, blk_after, blk_before=blk_after; t_before=anything, t_after=anything)
    (
        (tb, ta)
        for (tb, ta) in t_before_t(
            m; t_before=t_before, t_after=time_slice(m; temporal_block=members(blk_after), t=t_after), _compact=false
        )
        if !isdisjoint(members(blk_before), blocks(tb))
    )
end

"""
    node_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_time_indices(
    m::Model;
    node=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
    t=anything,
)
    (
        (node=n, t=t1)
        for n in intersect(node, SpineOpt.node())
        for t1 in time_slice(
            m;
            temporal_block=[
                tb
                for (_n, tbg) in node__temporal_block(node=n, temporal_block=temporal_block, _compact=false)
                for tb in members(tbg)
            ],
            t=t,
        )
    )
end

"""
    node_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_dynamic_time_indices(
    m::Model;
    node=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
    t_before=anything,
    t_after=anything,
)
    (
        (node=n, t_before=tb, t_after=ta)
        for n in intersect(node, SpineOpt.node())
        for (tb, ta) in dynamic_time_indices(
            m,
            (blk for (_n, blk) in node__temporal_block(node=n, temporal_block=temporal_block, _compact=false)),
            node__temporal_block(node=n);
            t_before=t_before,
            t_after=t_after,
        )
    )
end

"""
    unit_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t)` `NamedTuples` for `unit` online variables unit with filter keywords.
"""
function unit_time_indices(
    m::Model;
    unit=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
    t=anything,
)
    (
        (unit=u, t=t1)
        for u in intersect(unit, SpineOpt.unit())
        for t1 in time_slice(
            m;
            temporal_block=[
                tb
                for (_u, tbg) in units_on__temporal_block(unit=u, temporal_block=temporal_block, _compact=false)
                for tb in members(tbg)
            ],
            t=t,
        )
    )
end

"""
    unit_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t_before, t_after)` `NamedTuples` for `unit` online variables filter keywords.
"""
function unit_dynamic_time_indices(
    m::Model;
    unit=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
    t_before=anything,
    t_after=anything,
)
    (
        (unit=u, t_before=tb, t_after=ta)
        for u in intersect(unit, SpineOpt.unit())
        for (tb, ta) in dynamic_time_indices(
            m,
            (blk for (_u, blk) in units_on__temporal_block(unit=u, temporal_block=temporal_block, _compact=false));
            t_before=t_before,
            t_after=t_after
        )
    )
end

"""
    unit_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t)` `NamedTuples` for `unit` investment variables with filter keywords.
"""
function unit_investment_time_indices(m::Model; unit=anything, temporal_block=anything, t=anything)
    unit = intersect(unit, SpineOpt.unit(is_candidate=true))
    (
        (unit=u, t=t1)
        for (u, tb) in unit__investment_temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end

"""
    connection_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(connection, t)` `NamedTuples` for `connection` investment variables with filter keywords.
"""
function connection_investment_time_indices(m::Model; connection=anything, temporal_block=anything, t=anything)
    connection = intersect(connection, SpineOpt.connection(is_candidate=true))
    (
        (connection=conn, t=t1)
        for (conn, tb) in connection__investment_temporal_block(
            connection=connection, temporal_block=temporal_block, _compact=false
        )
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end

"""
    node_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t)` `NamedTuples` for `node` investment variables (storages) with filter keywords.
"""
function node_investment_time_indices(m::Model; node=anything, temporal_block=anything, t=anything)
    node = intersect(node, SpineOpt.node(is_candidate=true))
    (
        (node=n, t=t1)
        for (n, tb) in node__investment_temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end

"""
    unit_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t_before, t_after)` `NamedTuples` for `unit` investment variables with filters.
"""
function unit_investment_dynamic_time_indices(m::Model; unit=anything, t_before=anything, t_after=anything)
    (
        (unit=u, t_before=tb, t_after=ta)
        for u in intersect(unit, SpineOpt.unit(is_candidate=true))
        for (tb, ta) in dynamic_time_indices(
            m, unit__investment_temporal_block(unit=u); t_before=t_before, t_after=t_after
        )
    )
end

"""
    connection_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(connection, t_before, t_after)` `NamedTuples` for `connection` investment variables with filters.
"""
function connection_investment_dynamic_time_indices(m::Model; connection=anything, t_before=anything, t_after=anything)
    (
        (connection=conn, t_before=tb, t_after=ta)
        for conn in intersect(connection, SpineOpt.connection(is_candidate=true))
        for (tb, ta) in dynamic_time_indices(
            m, connection__investment_temporal_block(connection=conn); t_before=t_before, t_after=t_after
        )

    )
end

"""
    node_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` for `node` investment variables with filters.
"""
function node_investment_dynamic_time_indices(m::Model; node=anything, t_before=anything, t_after=anything)
    (
        (node=n, t_before=tb, t_after=ta)
        for n in intersect(node, SpineOpt.node(is_candidate=true))
        for (tb, ta) in dynamic_time_indices(
            m, node__investment_temporal_block(node=n); t_before=t_before, t_after=t_after
        )
    )
end

t_highest_resolution(m, t_iter) = t_highest_resolution!(m, collect(t_iter))

t_highest_resolution!(m, t_arr::Union{Vector,Dict}) = _t_extreme_resolution!(m, t_arr, :t_short)

t_lowest_resolution(m, t_iter) = t_lowest_resolution!(m, collect(t_iter))

t_lowest_resolution!(m, t_arr::Union{Vector,Dict}) = _t_extreme_resolution!(m, t_arr, :t_long)

function _t_extreme_resolution!(m, t_arr::Vector, kw)
    isempty(t_in_t_excl(m)) && return t_arr
    to_delete = t_in_t_excl(m; NamedTuple{(kw,)}((t_arr,))...)
    setdiff!(t_arr, to_delete)
end
function _t_extreme_resolution!(m, t_dict::Dict, kw)
    isempty(t_in_t_excl(m)) && return t_dict
    for t in t_in_t_excl(m; NamedTuple{(kw,)}((keys(t_dict),))...)
        delete!(t_dict, t)
    end
    t_dict
end

t_lowest_resolution_sets!(m, t_dict) = _t_extreme_resolution_sets!(m, t_dict, :t_long)

t_highest_resolution_sets!(m, t_dict) = _t_extreme_resolution_sets!(m, t_dict, :t_short)

function _t_extreme_resolution_sets!(m, t_dict, kw)
    isempty(t_in_t_excl(m)) && return t_dict
    for t in keys(t_dict)
        for other_t in t_in_t_excl(m; NamedTuple{(kw,)}((t,))...)
            union!(t_dict[t], pop!(t_dict, other_t, ()))
        end
    end
    t_dict
end

function (x::Union{Parameter,ParameterFunction})(m::Model; kwargs...)
    t0 = _analysis_time(m)
    algo = model_algorithm(model=m.ext[:spineopt].instance)
    @fetch as_number_or_call = m.ext[:spineopt].temporal_structure
    as_number_or_call(x; analysis_time=t0, algo_kwargs(m, Val(algo))..., kwargs...)
end

algo_kwargs(m, algo) = (;)

needs_auto_updating(algo) = false
