#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    function TimeSliceSet(time_slices, dur_unit)
        block_time_slices = Dict{Object,Array{TimeSlice,1}}()
        for t in time_slices
            for block in blocks(t)
                push!(get!(block_time_slices, block, []), t)
            end
        end
        # Bridge gaps in between temporal blocks
        solids = [(first(time_slices), last(time_slices)) for time_slices in values(block_time_slices)]
        sort!(solids)
        gap_bounds = (
            (prec_last, succ_first)
            for ((_pf, prec_last), (succ_first, _sl)) in zip(solids[1 : end - 1], solids[2:end])
            if end_(prec_last) < start(succ_first)
        )
        gaps = [
            TimeSlice(end_(prec_last), start(succ_first); duration_unit=dur_unit)
            for (prec_last, succ_first) in gap_bounds
        ]
        # NOTE: By convention, the first time slice in the succeeding block becomes the 'bridge'
        bridges = [succ_first for (_pl, succ_first) in gap_bounds]
        new(time_slices, block_time_slices, gaps, bridges)
    end
end

struct TOverlapsT
    overlapping_time_slices::Dict{TimeSlice,Array{TimeSlice,1}}
end

(h::TimeSliceSet)(; temporal_block=anything, t=anything) = h(temporal_block, t)
(h::TimeSliceSet)(::Anything, ::Anything) = h.time_slices
(h::TimeSliceSet)(temporal_block::Object, ::Anything) = h.block_time_slices[temporal_block]
(h::TimeSliceSet)(::Anything, t) = t
(h::TimeSliceSet)(temporal_block::Object, t) = TimeSlice[s for s in t if temporal_block in blocks(s)]
(h::TimeSliceSet)(temporal_blocks::Array{T,1}, t) where {T} = TimeSlice[s for blk in temporal_blocks for s in h(blk, t)]

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
function _model_duration_unit(instance::Object)
    get(Dict(:minute => Minute, :hour => Hour), duration_unit(model=instance, _strict=false), Minute)
end

function _model_window_duration(instance)
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
    _blocks_by_time_interval(instance, window_start, window_end)

A `Dict` mapping (start, end) tuples to an Array of temporal blocks where found.
"""
function _blocks_by_time_interval(instance::Object, window_start::DateTime, window_end::DateTime)
    blocks_by_time_interval = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    # TODO: In preprocessing, remove temporal_blocks without any node__temporal_block relationships?
    model_blocks = members(temporal_block())
    isempty(model_blocks) && error("model $instance doesn't have any temporal_blocks")
    for block in model_blocks
        adjusted_start = _adjusted_start(window_start, block_start(temporal_block=block, _strict=false))
        adjusted_end = _adjusted_end(window_start, window_end, block_end(temporal_block=block, _strict=false))
        time_slice_start = adjusted_start
        i = 1
        while time_slice_start < adjusted_end
            duration = resolution(temporal_block=block, i=i)
            duration !== nothing || break
            if iszero(duration)
                # TODO: Try to move this to a check...
                error("`resolution` of temporal block `$(block)` cannot be zero!")
            end
            time_slice_end = time_slice_start + duration
            if time_slice_end > adjusted_end
                time_slice_end = adjusted_end
                @info "the last time slice of temporal block $block has been cut to fit within the block"
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
        TimeSlice(interval..., blocks...; duration_unit=_model_duration_unit(instance))
        for (interval, blocks) in _blocks_by_time_interval(instance, window_start, window_end)
    ]
    sort!(window_time_slices)
end

function _add_padding_time_slice!(instance, window_end, window_time_slices)
    last_t = window_time_slices[argmax(end_.(window_time_slices))]
    temp_struct_end = end_(last_t)
    if temp_struct_end < window_end
        padding_t = TimeSlice(
            temp_struct_end, window_end, blocks(last_t)...; duration_unit=_model_duration_unit(instance)
        )
        push!(window_time_slices, padding_t)
        @info string(
            "an artificial time slice $padding_t has been added to blocks $(blocks(padding_t)), ",
            "so that the temporal structure fills the optimisation window ",
        )
    end
end

"""
    _required_history_duration(m::Model)

The required length of the included history based on parameter values that impose delays as a `Dates.Period`.
"""
function _required_history_duration(instance::Object)
    lookback_params = (
        min_up_time,
        min_down_time,
        scheduled_outage_duration,
        connection_flow_delay,
        unit_investment_lifetime,
        connection_investment_lifetime,
        storage_investment_lifetime
    )
    max_vals = (maximum_parameter_value(p) for p in lookback_params)
    init = _model_duration_unit(instance)(1)  # Dynamics always require at least 1 duration unit of history
    reduce(max, (val for val in max_vals if val !== nothing); init=init)
end

function _history_time_slices!(instance, window_start, window_end, window_time_slices)
    window_duration = window_end - window_start
    required_history_duration = _required_history_duration(instance)
    history_window_count = div(Minute(required_history_duration), Minute(window_duration), RoundUp)
    blocks_by_history_interval = Dict()
    for t in window_time_slices
        t_start, t_end = start(t), min(end_(t), window_end)
        t_start < t_end || continue
        union!(get!(blocks_by_history_interval, (t_start, t_end), Set()), SpineInterface.blocks(t))
    end
    history_window_time_slices = [
        TimeSlice(interval..., blocks...; duration_unit=_model_duration_unit(instance))
        for (interval, blocks) in blocks_by_history_interval
    ]
    sort!(history_window_time_slices)
    history_time_slices = Array{TimeSlice,1}()
    for k in 1:history_window_count
        history_window_time_slices .-= window_duration
        prepend!(history_time_slices, history_window_time_slices)
    end
    history_start = window_start - required_history_duration
    filter!(t -> end_(t) > history_start, history_time_slices)
    t_history_t = Dict(
        zip(history_time_slices .+ window_duration, history_time_slices)
    )
    history_time_slices, t_history_t
end
"""
    _generate_time_slice!(m::Model)

Create a `TimeSliceSet` containing `TimeSlice`s in the current window.

See [@TimeSliceSet()](@ref).
"""
function _generate_time_slice!(m::Model)
    instance = m.ext[:spineopt].instance
    window = current_window(m)
    window_start = start(window)
    window_end = end_(window)
    window_time_slices = _window_time_slices(instance, window_start, window_end)
    _add_padding_time_slice!(instance, window_end, window_time_slices)
    history_time_slices, t_history_t = _history_time_slices!(instance, window_start, window_end, window_time_slices)
    dur_unit = _model_duration_unit(instance)
    m.ext[:spineopt].temporal_structure[:time_slice] = TimeSliceSet(window_time_slices, dur_unit)
    m.ext[:spineopt].temporal_structure[:history_time_slice] = TimeSliceSet(history_time_slices, dur_unit)
    m.ext[:spineopt].temporal_structure[:t_history_t] = t_history_t
end

"""
    _output_time_slices(instance, window_start, window_end)

A `Dict` mapping outputs to an `Array` of `TimeSlice`s corresponding to the output's resolution.
"""
function _output_time_slices(instance::Object, window_start::DateTime, window_end::DateTime)
    output_time_slices = Dict{Object,Array{TimeSlice,1}}()
    for out in indices(output_resolution)
        if output_resolution(output=out) === nothing
            output_time_slices[out] = nothing
            continue
        end
        output_time_slices[out] = arr = TimeSlice[]
        time_slice_start = window_start
        i = 1
        while time_slice_start < window_end
            duration = output_resolution(output=out, i=i)
            if iszero(duration)
                # TODO: Try to move this to a check...
                error("`output_resolution` of output `$(out)` cannot be zero!")
            end
            time_slice_end = time_slice_start + duration
            if time_slice_end > window_end
                time_slice_end = window_end
                @warn("the last time slice of output $out has been cut to fit within the optimisation window")
            end
            push!(arr, TimeSlice(time_slice_start, time_slice_end; duration_unit=_model_duration_unit(instance)))
            iszero(duration) && break
            time_slice_start = time_slice_end
            i += 1
        end
    end
    output_time_slices
end

"""
    _generate_output_time_slice!(m::Model)

Create a `Dict`, for the output resolution.
"""
function _generate_output_time_slices!(m::Model)
    instance = m.ext[:spineopt].instance
    window_start = model_start(model=instance)
    window_end = model_end(model=instance)
    m.ext[:spineopt].temporal_structure[:output_time_slices] = _output_time_slices(instance, window_start, window_end)
end

"""
    _generate_time_slice_relationships()

E.g. `t_in_t`, `t_before_t`, `t_overlaps_t`...
"""
function _generate_time_slice_relationships!(m::Model)
    instance = m.ext[:spineopt].instance
    all_time_slices = Iterators.flatten((history_time_slice(m), time_slice(m)))
    duration_unit = _model_duration_unit(instance)
    succeeding_time_slices = Dict(
        t => to_time_slice(m, t=TimeSlice(end_(t), end_(t) + Minute(1))) for t in all_time_slices
    )
    overlapping_time_slices = Dict(t => to_time_slice(m, t=t) for t in all_time_slices)
    t_before_t_tuples = unique(
        (t_before, t_after)
        for (t_before, time_slices) in succeeding_time_slices
        for t_after in time_slices
        if end_(t_before) <= start(t_after)
    )
    t_in_t_tuples = unique(
        (t_short, t_long)
        for (t_short, time_slices) in overlapping_time_slices
        for t_long in time_slices
        if iscontained(t_short, t_long)
    )
    # Create the function-like objects
    temp_struct = m.ext[:spineopt].temporal_structure
    temp_struct[:t_before_t] = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_tuples)
    temp_struct[:t_in_t] = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_tuples)
    temp_struct[:t_overlaps_t] = TOverlapsT(overlapping_time_slices)
end

"""
    _generate_representative_time_slice!(m::Model)

Generate a `Dict` mapping all non-representative to representative time-slices
"""
function _generate_representative_time_slice!(m::Model)
    m.ext[:spineopt].temporal_structure[:representative_time_slice] = d = Dict()
    model_blocks = Set(members(temporal_block()))
    for represented_blk in indices(representative_periods_mapping)
        for (represented_t_start, representative_blk_name) in representative_periods_mapping(
            temporal_block=represented_blk
        )
            representative_blk = temporal_block(representative_blk_name)
            if !(representative_blk in model_blocks)
                error("representative temporal block $representative_blk is not in model $(m.ext[:spineopt].instance)")
            end
            for representative_t in time_slice(m, temporal_block=representative_blk)
                representative_t_duration = end_(representative_t) - start(representative_t)
                represented_t_end = represented_t_start + representative_t_duration
                new_d = Dict(
                    represented_t => [representative_t]
                    for represented_t in to_time_slice(m, t=TimeSlice(represented_t_start, represented_t_end))
                    if represented_blk in represented_t.blocks
                )
                merge!(append!, d, new_d)
                represented_t_start = represented_t_end
            end
        end
    end
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
    roll!.(t_set.time_slices, forward)
    roll!.(values(t_set.gaps), forward)
    roll!.(values(t_set.bridges), forward)
    nothing
end

function _refresh_time_slice_set!(t_set::TimeSliceSet)
    refresh!.(t_set.time_slices)
    refresh!.(values(t_set.gaps))
    refresh!.(values(t_set.bridges))
end

function generate_time_slice!(m::Model)
    _generate_time_slice!(m)
    _generate_output_time_slices!(m)
    _generate_time_slice_relationships!(m)
end

"""
    _generate_current_window!(m::Model)

Generate the current window TimeSlice for given model.
"""
function _generate_current_window!(m::Model)
    instance = m.ext[:spineopt].instance
    w_start = model_start(model=instance)
    w_end = w_start + _model_window_duration(instance)
    m.ext[:spineopt].temporal_structure[:current_window] = TimeSlice(
        w_start, w_end; duration_unit=_model_duration_unit(instance)
    )
end

function _generate_windows_and_window_count!(m::Model)
    instance = m.ext[:spineopt].instance
    w_start = model_start(model=instance)
    w_duration = _model_window_duration(instance)
    w_end = w_start + w_duration
    m.ext[:spineopt].temporal_structure[:windows] = windows = []
    push!(windows, TimeSlice(w_start, w_end; duration_unit=_model_duration_unit(instance)))
    i = 1
    while true
        rf = roll_forward(model=instance, i=i, _strict=false)
        (rf in (nothing, Minute(0)) || w_end >= model_end(model=instance)) && break
        w_start += rf
        w_start >= model_end(model=instance) && break
        w_end += rf
        push!(windows, TimeSlice(w_start, w_end; duration_unit=_model_duration_unit(instance)))
        i += 1
    end
    m.ext[:spineopt].temporal_structure[:window_count] = i
end

"""
    generate_temporal_structure!(m)

Create the temporal structure for the given SpineOpt model.
After this, you can call the following functions to query the generated structure.
- `time_slice`
- `t_before_t`
- `t_in_t`
- `t_overlaps_t`
- `to_time_slice`
- `current_window`
"""
function generate_temporal_structure!(m::Model)
    _generate_current_window!(m)
    _generate_windows_and_window_count!(m)
    generate_time_slice!(m)
    _generate_representative_time_slice!(m)
end

function _generate_master_window!(m_mp::Model)
    instance = m_mp.ext[:spineopt].instance
    mp_start = model_start(model=instance)
    mp_end = model_end(model=instance)
    m_mp.ext[:spineopt].temporal_structure[:current_window] = TimeSlice(
        mp_start, mp_end, duration_unit=_model_duration_unit(instance)
    )
end

"""
    generate_master_temporal_structure!(m_mp)

Create the Benders master problem temporal structure for given model.
"""
function generate_master_temporal_structure!(m_mp::Model)
    _generate_master_window!(m_mp)
    generate_time_slice!(m_mp)
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
    if !rev
        end_(temp_struct[:current_window]) >= model_end(model=m.ext[:spineopt].instance) && return false
        start(temp_struct[:current_window]) + rf >= model_end(model=m.ext[:spineopt].instance) && return false
    end
    roll!(temp_struct[:current_window], rf; refresh=false)
    _roll_time_slice_set!(temp_struct[:time_slice], rf)
    _roll_time_slice_set!(temp_struct[:history_time_slice], rf)
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
        _refresh_time_slice_set!(temp_struct[:time_slice])
        _refresh_time_slice_set!(temp_struct[:history_time_slice])
    end
end

"""
    to_time_slice(m; t)

An `Array` of `TimeSlice`s in model `m` overlapping the given `TimeSlice` (where `t` may not be in `m`).
"""
function to_time_slice(m::Model; t::TimeSlice)
    temp_struct = m.ext[:spineopt].temporal_structure
    t_sets = (temp_struct[:time_slice], temp_struct[:history_time_slice])
    in_blocks = (
        s
        for t_set in t_sets
        for time_slices in values(t_set.block_time_slices)
        for s in _to_time_slice(time_slices, t)
    )
    in_gaps = if isempty(indices(representative_periods_mapping))
        (
            s
            for t_set in t_sets
            for s in _to_time_slice(t_set.bridges, t_set.gaps, t)
        )
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

"""
    time_slice(m; temporal_block=anything, t=anything)

An `Array` of `TimeSlice`s in model `m`.

 # Keyword arguments
  - `temporal_block`: only return `TimeSlice`s in this block or blocks.
  - `t`: only return time slices from this collection.
"""
time_slice(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:time_slice](; kwargs...)

history_time_slice(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:history_time_slice](; kwargs...)

t_history_t(m::Model; t::TimeSlice) = get(m.ext[:spineopt].temporal_structure[:t_history_t], t, nothing)

"""
    t_before_t(m; t_before=anything, t_after=anything)

An `Array` where each element is a `Tuple` of two consecutive `TimeSlice`s in model `m`
(the second starting when the first ends).

 # Keyword arguments
  - `t_before`: if given, return an `Array` of `TimeSlice`s that start when `t_before` ends.
  - `t_after`: if given, return an `Array` of `TimeSlice`s that end when `t_after` starts.
"""
t_before_t(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:t_before_t](; kwargs...)

"""
    t_in_t(m; t_short=anything, t_long=anything)

An `Array` where each element is a `Tuple` of two `TimeSlice`s in model `m`,
the second containing the first.

 # Keyword arguments
  - `t_short`: if given, return an `Array` of `TimeSlice`s that contain `t_short`.
  - `t_long`: if given, return an `Array` of `TimeSlice`s that are contained in `t_long`.
"""
t_in_t(m::Model; kwargs...) = m.ext[:spineopt].temporal_structure[:t_in_t](; kwargs...)

"""
    t_overlaps_t(m; t)

An `Array` of `TimeSlice`s in model `m` that overlap the given `t`.
"""
t_overlaps_t(m::Model; t::TimeSlice) = m.ext[:spineopt].temporal_structure[:t_overlaps_t](t)

representative_time_slice(m, t) = get(m.ext[:spineopt].temporal_structure[:representative_time_slice], t, [t])

function output_time_slices(m::Model; output::Object)
    get(m.ext[:spineopt].temporal_structure[:output_time_slices], output, nothing)
end

"""
    node_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_time_indices(m::Model; node=anything, temporal_block=anything, t=anything)
    unique(
        (node=n, t=t1)
        for (n, tb) in node__temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(m; temporal_block=members(tb), t=t)
    )
end

"""
    node_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` with keyword arguments that allow filtering.
"""
function node_dynamic_time_indices(m::Model; node=anything, t_before=anything, t_after=anything)
    unique(
        (node=n, t_before=tb, t_after=ta)
        for (n, ta) in node_time_indices(m; node=node, t=t_after)
        for (n, tb) in node_time_indices(
            m; node=n, t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false))
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
function unit_dynamic_time_indices(
    m::Model;
    unit=anything,
    t_before=anything,
    t_after=anything,
    temporal_block=anything,
)
    unique(
        (unit=u, t_before=tb, t_after=ta)
        for (u, ta) in unit_time_indices(m; unit=unit, t=t_after)
        for (u, tb) in unit_time_indices(
            m;
            unit=u,
            t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false)),
            temporal_block=temporal_block,
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
        for (u, tb) in unit__investment_temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
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
    unique(
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
    unique(
        (unit=u, t_before=tb, t_after=ta)
        for (u, ta) in unit_investment_time_indices(m; unit=unit, t=t_after)
        for (u, tb) in unit_investment_time_indices(
            m; unit=u, t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false))
        )
    )
end

"""
    connection_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(connection, t_before, t_after)` `NamedTuples` for `connection` investment variables with filters.
"""
function connection_investment_dynamic_time_indices(m::Model; connection=anything, t_before=anything, t_after=anything)
    unique(
        (connection=conn, t_before=tb, t_after=ta)
        for (conn, ta) in connection_investment_time_indices(m; connection=connection, t=t_after)
        for (conn, tb) in connection_investment_time_indices(
            m; connection=conn, t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false))
        )
    )
end

"""
    node_investment_dynamic_time_indices(m::Model;<keyword arguments>)

Generate an `Array` of all valid `(node, t_before, t_after)` `NamedTuples` for `node` investment variables with filters.
"""
function node_investment_dynamic_time_indices(m::Model; node=anything, t_before=anything, t_after=anything)
    unique(
        (node=n, t_before=tb, t_after=ta)
        for (n, ta) in node_investment_time_indices(m; node=node, t=t_after)
        for (node, tb) in node_investment_time_indices(
            m; node=n, t=map(t -> t.t_before, t_before_t(m; t_before=t_before, t_after=ta, _compact=false))
        )
    )
end
