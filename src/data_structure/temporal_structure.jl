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

struct GapBridger
    gaps::Array{TimeSlice,1}
    bridges::Array{TimeSlice,1}
end

struct TimeSliceSet
    time_slices::Array{TimeSlice,1}
    block_time_slices::Dict{Object,Array{TimeSlice,1}}
    gap_bridger::GapBridger
    function TimeSliceSet(time_slices)
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t in time_slices
            for block in blocks(t)
                push!(get!(block_time_slices, block, []), t)
            end
        end
        # Find eventual gaps in between temporal blocks
        solids = [(first(time_slices), last(time_slices)) for time_slices in values(block_time_slices)]
        sort!(solids)
        gap_bounds = (
            (last_, next_first) for
            ((first_, last_), (next_first, next_last)) in zip(solids[1:end-1], solids[2:end]) if
            end_(last_) < start(next_first)
        )
        gaps = [TimeSlice(end_(last_), start(next_first)) for (last_, next_first) in gap_bounds]
        # NOTE: For convention, the last time slice in the preceding block becomes the 'bridge'
        bridges = [last_ for (last_, next_first) in gap_bounds]
        gap_bridger = GapBridger(gaps, bridges)
        new(time_slices, block_time_slices, gap_bridger)
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
(h::TimeSliceSet)(; temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, s) = s
(h::TimeSliceSet)(temporal_block::Object, s) = [t for t in s if temporal_block in blocks(t)]
(h::TimeSliceSet)(temporal_blocks::Array{T,1}, s) where {T} = [t for blk in temporal_blocks for t in h(blk, s)]

"""
    (::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})

A list of time slices that have some time in common with `t` or any time slice in `t`.
"""
function (h::TOverlapsT)(t::Union{TimeSlice,Array{TimeSlice,1}})
    unique(overlapping_t for s in t for overlapping_t in get(h.mapping, s, ()))
end

"""
    _roll_time_slice_set!(t_set::TimeSliceSet, forward::Union{Period,CompoundPeriod})

Roll a `TimeSliceSet` in time by a period specified by `forward`.
"""
function _roll_time_slice_set!(t_set::TimeSliceSet, forward::Union{Period,CompoundPeriod})
    roll!.(t_set.time_slices, forward)
    roll!.(values(t_set.gap_bridger.gaps), forward)
    roll!.(values(t_set.gap_bridger.bridges), forward)
    nothing
end

"""
    _model_duration_unit(instance::Object)

Fetch the `duration_unit` parameter of the first defined `model`, and defaults to `Minute` if not found.
"""
function _model_duration_unit(instance::Object)
    get(Dict(:minute => Minute, :hour => Hour), duration_unit(model=instance, _strict=false), Minute)
end

"""
    _generate_current_window!(m::Model)

A `TimeSlice` spanning the current optimization window from the beginning of the current solve until the beginning of
the next solve or `model_end`, whichever is defined and sooner.
"""
function _generate_current_window!(m::Model)
    instance = m.ext[:instance]
    model_start_ = model_start(model=instance)
    model_end_ = model_end(model=instance)
    roll_forward_ = roll_forward(model=instance, _strict=false)
    window_start = model_start_
    window_end = (roll_forward_ === nothing) ? model_end_ : min(model_start_ + roll_forward_, model_end_)
    m.ext[:temporal_structure][:current_window] =
        TimeSlice(window_start, window_end; duration_unit=_model_duration_unit(instance))
end

# Adjuster functions, in case blocks specify their own start and end
"""
    _adjuster_start(window_start, window_end, blk_start)

Adjust the `window_start` based on `temporal_blocks`.
"""
_adjusted_start(window_start::DateTime, ::Nothing) = window_start
_adjusted_start(window_start::DateTime, blk_start::Union{Period,CompoundPeriod}) = window_start + blk_start
_adjusted_start(window_start::DateTime, blk_start::DateTime) = max(window_start, blk_start)

"""
    _adjusted_end(window_start, window_end, blk_end)

Adjust the `window_end` based on `temporal_blocks`.
"""
_adjusted_end(::DateTime, window_end::DateTime, ::Nothing) = window_end
_adjusted_end(window_start::DateTime, ::DateTime, blk_end::Union{Period,CompoundPeriod}) = window_start + blk_end
_adjusted_end(window_start::DateTime, ::DateTime, blk_end::DateTime) = max(window_start, blk_end)

"""
    _time_interval_blocks(instance, window_start, window_end)

A `Dict` mapping 'pre-time_slices' (i.e., (start, end) tuples) to an Array of temporal blocks where found.
"""
function _time_interval_blocks(instance::Object, window_start::DateTime, window_end::DateTime)
    blocks_by_time_interval = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    # TODO: In preprocessing, remove temporal_blocks without any node__temporal_block relationships?
    for block in members(model__temporal_block(model=instance))
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
                # TODO: Try removing this to a once-off check as if true, this warning appears each time a timeslice is used
                @warn( """
                       the last time slice of temporal block $block has been cut to fit within the optimisation window
                       """)
            end
            push!(get!(blocks_by_time_interval, (time_slice_start, time_slice_end), Array{Object,1}()), block)
            time_slice_start = time_slice_end
            i += 1
        end
    end
    blocks_by_time_interval
end

"""
    _window_time_slices(instance, window_start, window_end)

A sorted `Array` of `TimeSlices` in the given window.
"""
function _window_time_slices(instance::Object, window_start::DateTime, window_end::DateTime)
    window_time_slices = [
        TimeSlice(t..., blocks...; duration_unit=_model_duration_unit(instance))
        for (t, blocks) in _time_interval_blocks(instance, window_start, window_end)
    ]
    sort!(window_time_slices)
end

"""
    _generate_time_slice!(m::Model)

Create and export a `TimeSliceSet` containing `TimeSlice`s in the current window.

See [@TimeSliceSet()](@ref).
"""
function _generate_time_slice!(m::Model)
    instance = m.ext[:instance]
    window = current_window(m)
    window_start = start(window)
    window_end = end_(window)
    window_time_slices = _window_time_slices(instance, window_start, window_end)
    history_time_slices = Array{TimeSlice,1}()
    required_history_duration = _required_history_duration(instance)
    window_duration = window_end - window_start
    history_window_count = div(Minute(required_history_duration), Minute(window_duration))
    i = findlast(t -> end_(t) <= window_end, window_time_slices)
    history_window_time_slices = window_time_slices[1:i] .- window_duration
    for k in 1:history_window_count
        prepend!(history_time_slices, history_window_time_slices)
        history_window_time_slices .-= window_duration
    end
    history_start = window_start - required_history_duration
    filter!(t -> end_(t) > history_start, history_window_time_slices)
    prepend!(history_time_slices, history_window_time_slices)
    m.ext[:temporal_structure][:time_slice] = TimeSliceSet(window_time_slices)
    m.ext[:temporal_structure][:history_time_slice] = TimeSliceSet(history_time_slices)
    m.ext[:temporal_structure][:t_history_t] = Dict(zip(history_time_slices .+ window_duration, history_time_slices))
end

"""
    _required_history_duration(m::Model)

The required length of the included history based on parameter values that impose delays as a `Dates.Period`.
"""
function _required_history_duration(instance::Object)
    delay_params = (min_up_time, min_down_time, connection_flow_delay, unit_investment_lifetime, connection_investment_lifetime, storage_investment_lifetime)
    max_vals = (maximum_parameter_value(p) for p in delay_params)
    init = _model_duration_unit(instance)(1)  # Dynamics always require at least 1 duration unit of history
    reduce(max, (val for val in max_vals if val !== nothing); init=init)
end


"""
    _generate_time_slice_relationships()

E.g. `t_in_t`, `t_preceeds_t`, `t_overlaps_t`...
"""
function _generate_time_slice_relationships!(m::Model)
    instance = m.ext[:instance]
    all_time_slices = Iterators.flatten((history_time_slice(m), time_slice(m)))
    duration_unit = _model_duration_unit(instance)
    t_follows_t_mapping =
        Dict(t => to_time_slice(m, t=TimeSlice(end_(t), end_(t) + Minute(1))) for t in all_time_slices)
    t_overlaps_t_maping = Dict(t => to_time_slice(m, t=t) for t in all_time_slices)
    t_overlaps_t_excl_mapping = Dict(t => setdiff(overlapping_t, t) for (t, overlapping_t) in t_overlaps_t_maping)
    t_before_t_tuples = unique(
        (t_before=t_before, t_after=t_after) for (t_before, following) in t_follows_t_mapping
        for t_after in following if before(t_before, t_after)
    )
    t_in_t_tuples = unique(
        (t_short=t_short, t_long=t_long) for (t_short, overlapping) in t_overlaps_t_maping
        for t_long in overlapping if iscontained(t_short, t_long)
    )
    t_in_t_excl_tuples = [(t_short=t1, t_long=t2) for (t1, t2) in t_in_t_tuples if t1 != t2]
    # Create the function-like objects
    temp_struct = m.ext[:temporal_structure]
    temp_struct[:t_before_t] = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_tuples)
    temp_struct[:t_in_t] = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_tuples)
    temp_struct[:t_in_t_excl] = RelationshipClass(:t_in_t_excl, [:t_short, :t_long], t_in_t_excl_tuples)
    temp_struct[:t_overlaps_t] = TOverlapsT(t_overlaps_t_maping)
    temp_struct[:t_overlaps_t_excl] = TOverlapsT(t_overlaps_t_excl_mapping)
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

# API
"""
    generate_temporal_structure!(m::Model)

Preprocess the temporal structure for SpineOpt from the provided input data.

Runs a number of functions processing different aspects of the temporal structure in sequence.
"""
function generate_temporal_structure!(m::Model)
    m.ext[:temporal_structure] = Dict()
    _generate_current_window!(m::Model)
    _generate_time_slice!(m::Model)
    _generate_time_slice_relationships!(m::Model)
    _generate_representative_time_slice_mapping(m::Model)
end


"""
    roll_temporal_structure!(m::Model)

Move the entire temporal structure ahead according to the `roll_forward` parameter.
"""
function roll_temporal_structure!(m::Model)
    instance = m.ext[:instance]
    temp_struct = m.ext[:temporal_structure]
    end_(temp_struct[:current_window]) >= model_end(model=instance) && return false
    roll_forward_ = roll_forward(model=instance, _strict=false)
    roll_forward_ in (nothing, 0) && return false
    roll!(temp_struct[:current_window], roll_forward_)
    _roll_time_slice_set!(temp_struct[:time_slice], roll_forward_)
    _roll_time_slice_set!(temp_struct[:history_time_slice], roll_forward_)
    true
end


"""
    reset_temporal_structure!(m::Model, k)

Rewind the temporal structure - essentially, rolling it backwards k times.
"""
function reset_temporal_structure(m::Model, k)
    end_(current_window(m)) >= model_end(model=m.ext[:instance]) && return false
    roll_forward_ = roll_forward(model=m, _strict=false)
    roll_forward_ === nothing && return false
    roll_forward_ == 0 && return false
    roll!(current_window(m), -roll_forward_ * k)
    roll!.(all_time_slices, -roll_forward_ * k)
    true
end

current_window(m::Model) = m.ext[:temporal_structure][:current_window]
time_slice(m::Model; kwargs...) = m.ext[:temporal_structure][:time_slice](; kwargs...)
history_time_slice(m::Model; kwargs...) = m.ext[:temporal_structure][:history_time_slice](; kwargs...)
t_history_t(m::Model; t::TimeSlice) = get(m.ext[:temporal_structure][:t_history_t], t, nothing)
t_before_t(m::Model; kwargs...) = m.ext[:temporal_structure][:t_before_t](; kwargs...)
t_in_t(m::Model; kwargs...) = m.ext[:temporal_structure][:t_in_t](; kwargs...)
t_in_t_excl(m::Model; kwargs...) = m.ext[:temporal_structure][:t_in_t_excl](; kwargs...)
t_overlaps_t(m::Model; t::TimeSlice) = m.ext[:temporal_structure][:t_overlaps_t](t)
t_overlaps_t_excl(m::Model; t::TimeSlice) = m.ext[:temporal_structure][:t_overlaps_t_excl](t)

"""
    to_time_slice(m::Model, t::TimeSlice...)

An `Array` of `TimeSlice`s *in the model* overlapping the given `t` (where `t` may not be in model).
"""
function to_time_slice(m::Model; t::TimeSlice)
    temp_struct = m.ext[:temporal_structure]
    t_sets = (temp_struct[:time_slice], temp_struct[:history_time_slice])
    in_blocks = (
        s for t_set in t_sets for time_slices in values(t_set.block_time_slices) for s in _to_time_slice(time_slices, t)
    )
    in_gaps = (s for t_set in t_sets for s in _to_time_slice(t_set.gap_bridger.bridges, t_set.gap_bridger.gaps, t))
    unique(Iterators.flatten((in_blocks, in_gaps)))
end

"""
    _generate_representative_time_slice_mapping(m::Model)
Generate an `Array` mapping all non-representative to representative time-slices
"""
function _generate_representative_time_slice_mapping(m::Model)
    rep_dict=Dict()
    for blk in indices(representative_periods_mapping)
        for t_start_real in representative_periods_mapping(temporal_block=blk).indexes
            rep_blk = representative_periods_mapping(temporal_block=blk, inds=t_start_real)
            t_start_real_i = t_start_real
            for t in time_slice(m, temporal_block=temporal_block(rep_blk))
                rep_dict[to_time_slice(m,t=TimeSlice(t_start_real_i,t_start_real_i + _model_duration_unit(m.ext[:instance])(duration(t))))] = t
                t_start_real_i = t_start_real_i + _model_duration_unit(m.ext[:instance])(duration(t))
            end
        end
    end
    m.ext[:temporal_structure][:rep_day_mapping] = rep_dict
end

representative_time_slices(m) = m.ext[:temporal_structure][:rep_day_mapping]
"""
    node_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_time_indices(m::Model; node=anything, temporal_block=anything, t=anything)
    unique(
        (node=n, t=t1) for (n, tb) in node__temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end

"""
    node_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_dynamic_time_indices(m::Model; node=anything, t_before=anything, t_after=anything)
    unique(
        (node=n, t_before=tb, t_after=ta) for (n, ta) in node_time_indices(m; node=node, t=t_after)
        for
        (n, tb) in node_time_indices(
            m;
            node=n,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
        )
    )
end

"""
    unit_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t)` `NamedTuples` for `unit` online variables unit with filter keywords.
"""
function unit_time_indices(m::Model; unit=anything, temporal_block=temporal_block(representative_periods_mapping=nothing) , t=anything)
    unique(
        (unit=u, t=t1)
        for (u, tb) in units_on__temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end


"""
    unit_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t_before, t_after)` `NamedTuples` for `unit` online variables filter keywords.
"""
function unit_dynamic_time_indices(m::Model; unit=anything, t_before=anything, t_after=anything, temporal_block=anything)
    unique(
        (unit=u, t_before=tb, t_after=ta) for (u, ta) in unit_time_indices(m; unit=unit, t=t_after)
        for
        (u, tb) in unit_time_indices(
            m;
            unit=u,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
            temporal_block=temporal_block
        )
    )
end

"""
    unit_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t)` `NamedTuples` for `unit` investment variables with filter keywords.
"""
function unit_investment_time_indices(m::Model; unit=anything, temporal_block=anything, t=anything)
    unique(
        (unit=u, t=t1)
        for (u, tb) in unit__investment_temporal_block(unit=unit, temporal_block=temporal_block, _compact=false) if tb in model__temporal_block(model=m.ext[:instance])
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end


"""
    connection_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(connection, t)` `NamedTuples` for `connection` investment variables with filter keywords.
"""
function connection_investment_time_indices(m::Model; connection=anything, temporal_block=anything, t=anything)
    unique(
        (connection=conn, t=t1)
        for (conn, tb) in connection__investment_temporal_block(connection=connection, temporal_block=temporal_block, _compact=false) if tb in model__temporal_block(model=m.ext[:instance])
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end


"""
    node_investment_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t)` `NamedTuples` for `node` investment variables (storages) with filter keywords.
"""
function node_investment_time_indices(m::Model; node=anything, temporal_block=anything, t=anything)
    unique(
        (node=n, t=t1)
        for (n, tb) in node__investment_temporal_block(node=node, temporal_block=temporal_block, _compact=false) if tb in model__temporal_block(model=m.ext[:instance])
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end


"""
    unit_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(unit, t_before, t_after)` `NamedTuples` for `unit` investment variables with filters.
"""
function unit_investment_dynamic_time_indices(m::Model; unit=anything, t_before=anything, t_after=anything)
    unique(
        (unit=u, t_before=tb, t_after=ta) for (u, ta) in unit_investment_time_indices(m; unit=unit, t=t_after)
        for
        (u, tb) in unit_investment_time_indices(
            m;
            unit=u,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
        )
    )
end


"""
    connection_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(connection, t_before, t_after)` `NamedTuples` for `connection` investment variables with filters.
"""
function connection_investment_dynamic_time_indices(m::Model; connection=anything, t_before=anything, t_after=anything)
    unique(
        (connection=conn, t_before=tb, t_after=ta) for (conn, ta) in connection_investment_time_indices(m; connection=connection, t=t_after)
        for
        (conn, tb) in connection_investment_time_indices(
            m;
            connection=conn,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
        )
    )
end


"""
    node_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` for `node` investment variables with filters.
"""
function node_investment_dynamic_time_indices(m::Model; node=anything, t_before=anything, t_after=anything)
    unique(
        (node=n, t_before=tb, t_after=ta) for (n, ta) in node_investment_time_indices(m; node=node, t=t_after)
        for
        (node, tb) in node_investment_time_indices(
            m;
            node=n,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
        )
    )
end
