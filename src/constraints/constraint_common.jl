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

function _add_constraint!(m::Model, name::Symbol, indices, build_constraint)
    inds = collect(indices(m))
    cons = Any[nothing for i in 1:length(inds)]
    Threads.@threads for i in 1:length(inds)
        ind = inds[i]
        cons[i] = build_constraint(m, ind...)
    end
    m.ext[:spineopt].constraints[name] = Dict(zip(inds, add_constraint.(m, cons)))
end

"""
    t_lowest_resolution_path(m, indices...)

An iterator of tuples `(t, path)` where `t` is a `TimeSlice` and `path` is a `Vector` of stochastic scenario `Object`s
corresponding to the active stochastic paths for that `t`.
The `t`s in the result are the lowest resolution `TimeSlice`s in `indices`.
For each of these `t`s, the `path` also includes scenarios in `extra_indices` where the `TimeSlice` contains the `t`.
"""
function t_lowest_resolution_path(m, indices, extra_indices...)
    isempty(indices) && return ()
    if length(stochastic_scenario()) == 1
        s = only(stochastic_scenario())
        return ((t, [s]) for t in t_lowest_resolution!(m, unique(x.t for x in indices)))
    end
    scens_by_t = t_lowest_resolution_sets!(m, _scens_by_t(indices))
    extra_scens_by_t = _scens_by_t(Iterators.flatten(extra_indices))
    for (t, scens) in scens_by_t
        for t_long in t_in_t(m; t_short=t)
            union!(scens, get(extra_scens_by_t, t_long, ()))
        end
    end
    ((t, path) for (t, scens) in scens_by_t for path in active_stochastic_paths(m, scens))
end

function _popfirst!(arr, default)
    try popfirst!(arr) catch default end
end

function _scens_by_t(indices)
    scens_by_t = Dict{TimeSlice,Set}()
    for x in indices
        scens = get!(scens_by_t, x.t) do
            Set{Object}()
        end
        push!(scens, x.stochastic_scenario)
    end
    scens_by_t
end

past_units_on_indices(args...) = past_unit_indices(units_on_indices, args...)

past_units_out_of_service_indices(args...) = past_unit_indices(units_out_of_service_indices, args...)

function past_unit_indices(indices, m, u, s_path, t, min_time)
    t0 = _analysis_time(m)
    indices(
        m;
        unit=u,
        stochastic_scenario=s_path,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - min_time(unit=u, analysis_time=t0, stochastic_scenario=s_path, t=t), end_(t))
        ),
        temporal_block=anything
    )    
end

function _minimum_operating_point(m, u, ng, d, s, t0, t)
    minimum_operating_point(m; unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=0)
end

function _unit_flow_capacity(m, u, ng, d, s, t0, t)
    unit_flow_capacity(m; unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
end

function _start_up_limit(m, u, ng, d, s, t0, t)
    start_up_limit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)
end

function _shut_down_limit(m, u, ng, d, s, t0, t)
    shut_down_limit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)
end

"""
    _switch(d; from_node, to_node)

Either `from_node` or `to_node` depending on the given direction `d`.

# Example

```julia
@assert _switch(direction(:from_node); from_node=3, to_node=-1) == 3
@assert _switch(direction(:to_node); from_node=3, to_node=-1) == -1
```
"""
function _switch(d; from_node, to_node)
    Dict(:from_node => from_node, :to_node => to_node)[d.name]
end

"""
    _d_reverse(d)

Obtain the reverse direction Object of a given direction Object `d`.
The `direction` ObjectClass is already defined by `generate_direction()`
in "src\\data_structure\\preprocess_data_structure.jl".

# Example

```julia
@assert _d_reverse(direction(:from_node)) == direction(:to_node)
```
"""
_d_reverse(d::Object) = d.name == :to_node ? direction(:from_node) : direction(:to_node)

_overlapping_t(m, time_slices...) = [overlapping_t for t in time_slices for overlapping_t in t_overlaps_t(m; t=t)]

function _check_ptdf_duration(m, t, conns...)
    durations = [ptdf_duration(connection=conn, _default=nothing) for conn in conns]
    filter!(!isnothing, durations)
    isempty(durations) && return true
    duration = minimum(durations)
    elapsed = end_(t) - start(current_window(m))
    Dates.toms(duration - elapsed) >= 0
end