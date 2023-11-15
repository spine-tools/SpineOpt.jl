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

"""
    t_lowest_resolution_path(m, indices...)

An iterator of tuples `(t, path)` where `t` is a `TimeSlice` and `path` is a `Vector` of stochastic scenario `Object`s
corresponding to the active stochastic paths for that `t`.
The `t`s in the result are the lowest resolution `TimeSlice`s in `indices`.
For each of these `t`s, the `path` also includes scenarios in `more_indices` where the `TimeSlice` contains the `t`.
"""
function t_lowest_resolution_path(m, indices, more_indices...)
    isempty(indices) && return ()
    scens_by_t = t_lowest_resolution_sets!(_scens_by_t(indices))
    for (other_t, other_scens) in _scens_by_t(Iterators.flatten(more_indices))
        for (t, scens) in scens_by_t
            if iscontained(t, other_t)
                union!(scens, other_scens)
            end
        end
    end
    ((t, path) for (t, scens) in scens_by_t for path in active_stochastic_paths(m, scens))
end

function _scens_by_t(indices)
    scens_by_t = Dict()
    for x in indices
        scens = get!(scens_by_t, x.t) do
            Set{Object}()
        end
        push!(scens, x.stochastic_scenario)
    end
    scens_by_t
end

function past_units_on_indices(m, u, s, t, min_time)
    t0 = _analysis_time(m)
    units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - min_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t))
        ),
        temporal_block=anything
    )    
end

function _minimum_operating_point(u, ng, d, s, t0, t)
    minimum_operating_point[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function _unit_flow_capacity(u, ng, d, s, t0, t)
    (
        + unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
        * unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
        * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
    )
end

function _start_up_limit(u, ng, d, s, t0, t)
    start_up_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function _shut_down_limit(u, ng, d, s, t0, t)
    shut_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

"""
    _is_reserve_node(n, d; from_node, to_node)

Whether the given node is a reserve node for given direction of flow.
Keyword arguments `from_node` and `to_node` should either be `upward_reserve` or `downward_reserve`,
indicating which type of reserve is considered relevant for each direction.

# Example

```julia

n = node(:some_node)

@assert upwards_reserve(node=n) && !downwards_reserve(node=n)
@assert _is_reserve_node(n, direction(:from_node); from_node=upwards_reserve, to_node=downwards_reserve)
@assert !_is_reserve_node(n, direction(:from_node); from_node=downwards_reserve, to_node=upwards_reserve)
```
"""
function _is_reserve_node(n, d; from_node, to_node)
    is_reserve_node(node=n) && Dict(direction(:from_node) => from_node, direction(:to_node) => to_node)[d](node=n)
end

_overlapping_t(m, time_slices...) = [overlapping_t for t in time_slices for overlapping_t in t_overlaps_t(m; t=t)]
