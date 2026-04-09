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

@doc raw"""
In a multi-commodity setting, there can be different commodities entering/leaving a certain
technology/unit. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The [unit\_capacity](@ref) must be specified
for at least one [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship,
in order to trigger a constraint on the maximum commodity flows to this location in each time step.
When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products).

```math
\begin{aligned}
& \sum_{
        n \in ng
}
    v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[ \neg p^{is\_reserve\_node}_{(n)} \right]\\
& + \sum_{
        n \in ng
}
    v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[
        p^{is\_reserve\_node}_{(n)} \land p^{upward\_reserve}_{(n)} \land \neg p^{is\_non\_spinning}_{(n)} 
    \right]\\
& \le \\
& p^{unit\_capacity}_{(u,ng,d,s,t)} \cdot p^{unit\_availability\_factor}_{(u,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,ng,d,s,t)} \\
& \cdot ( \\
& \qquad v^{units\_on}_{(u,s,t)} \\
& \qquad - \left(1 - p^{shut\_down\_limit}_{(u,ng,d,s,t)}\right)
\cdot \left( v^{units\_shut\_down}_{(u,s,t+1)}
+ \sum_{
    n \in ng
} v^{nonspin\_units\_shut\_down}_{(u,n,s,t)} \right) \\
& \qquad - \left(1 - p^{start\_up\_limit}_{(u,ng,d,s,t)}\right) \cdot v^{units\_started\_up}_{(u,s,t)} \\
& ) \\
& \forall (u,ng,d) \in indices(p^{unit\_capacity}) \\
& \forall (s,t)
\end{aligned}
```
where
```math
[p] \vcentcolon = \begin{cases}
1 & \text{if } p \text{ is true;}\\
0 & \text{otherwise.}
\end{cases}
```

!!! note
    The conversion factor [unit\_conv\_cap\_to\_flow](@ref) has a default value of `1`, but can be adjusted
    in case the unit of measurement for the capacity is different to the unit flows unit of measurement.

!!! note
    The above formulation is valid for time-slices whose duration is greater than the minimum up time of the unit.
    This ensures that the unit is not online for exactly one time-slice, which might result in an infeasibility
    if this formulation was used.
    Instead, for time-slices whose duration is lower or equal than the minimum up time of the unit there is a similar
    formulation, but the details are omitted for brevity.

!!! note
    The above formulation is valid for flows going from a unit to a node (i.e., output flows).
    For flows going from a node to a unit (i.e., input flows) the direction of the reserves is switched
    (downwards becomes upwards, non-spinning units shut-down becomes non-spinning units started-up).
    The details are omitted for brevity.

See also
[is\_reserve\_node](@ref),
[upward\_reserve](@ref),
[is\_non\_spinning](@ref),
[unit\_capacity](@ref),
[unit\_availability\_factor](@ref),
[unit\_conv\_cap\_to\_flow](@ref),
[start\_up\_limit](@ref),
[shut\_down\_limit](@ref).
"""
function add_constraint_unit_flow_capacity!(m::Model)
    if use_tight_compact_formulations(model=m.ext[:spineopt].instance, _default=false)
        _add_constraint_unit_flow_capacity_tight_compact!(m)
    else
        _add_constraint_unit_flow_capacity_simple!(m)
    end
end

function _add_constraint_unit_flow_capacity_tight_compact!(m::Model)
    _add_constraint!(
        m,
        :unit_flow_capacity,
        constraint_unit_flow_capacity_tight_compact_indices,
        _build_constraint_unit_flow_capacity_tight_compact,
    )
end

function _build_constraint_unit_flow_capacity_tight_compact(m::Model, u, ng, d, s_path, t, t_next, case, part)
    @fetch (
        units_started_up, units_shut_down, nonspin_units_started_up, nonspin_units_shut_down
    ) = m.ext[:spineopt].variables
    @build_constraint(
        + _term_unit_flow(m, u, ng, d, s_path, t)
        <=
        + _term_flow_capacity(m, u, ng, d, s_path, t)
        - (
            + sum(
                + _shutdown_margin(m, u, ng, d, s, t, case, part)
                * _unit_flow_capacity(m, u, ng, d, s, t)
                * units_shut_down[u, s, t_after]
                * duration(t_after)
                for (u, s, t_after) in units_switched_indices(m; unit=u, stochastic_scenario=s_path, t=t_next);
                init=0,
            )
            + sum(
                + _shutdown_margin(m, u, ng, d, s, t, case, part)
                * _unit_flow_capacity(m, u, ng, d, s, t)
                * _switch(
                    d; from_node=nonspin_units_started_up, to_node=nonspin_units_shut_down
                )[u, n, s, t_over]
                * overlap_duration(t_over, t)
                for (u, n, s, t_over) in _switch(
                    d; from_node=nonspin_units_started_up_indices, to_node=nonspin_units_shut_down_indices
                )(m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t));
                init=0,
            )
        )
        - sum(
            + _startup_margin(m, u, ng, d, s, t, case, part)
            * _unit_flow_capacity(m, u, ng, d, s, t)
            * units_started_up[u, s, t_over]
            for (u, s, t_over) in units_switched_indices(
                m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
            );
            init=0,
        )
    )
end

function _add_constraint_unit_flow_capacity_simple!(m::Model)
    _add_constraint!(
        m, :unit_flow_capacity, constraint_unit_flow_capacity_indices, _build_constraint_unit_flow_capacity
    )
end

function _build_constraint_unit_flow_capacity(m::Model, u, ng, d, s_path, t)
    @build_constraint(_term_unit_flow(m, u, ng, d, s_path, t) <= _term_flow_capacity(m, u, ng, d, s_path, t))
end

function _term_unit_flow(m, u, ng, d, s_path, t)
    @fetch unit_flow = m.ext[:spineopt].variables
    sum(
        get(unit_flow, (u, n, d, s, t_over), 0) * overlap_duration(t_over, t)
        for n in members(ng), s in s_path, t_over in t_overlaps_t(m; t=t)
        if _is_regular_node(n, d);
        init=0,
    )
end

function _term_flow_capacity(m, u, ng, d, s_path, t)
    sum(
        _unit_flow_capacity(m, u, ng, d, s, t) * _get_units_on(m, u, s, t_over) * overlap_duration(t_over, t)
        for (u, s, t_over) in unit_stochastic_time_indices(
            m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
        );
        init=0,
    )
end

function _shutdown_margin(m, u, ng, d, s, t, case, part)
    if part.name == :one
        # (F - SD)
        1 - _shut_down_limit(m, u, ng, d, s, t)
    else
        # max(SU - SD, 0)
        max(_start_up_limit(m, u, ng, d, s, t) - _shut_down_limit(m, u, ng, d, s, t), 0)
    end
end

function _startup_margin(m, u, ng, d, s, t, case, part)
    if case.name == :min_up_time_le_time_step && part.name == :one
        # max(SD - SU, 0)
        max(_shut_down_limit(m, u, ng, d, s, t) - _start_up_limit(m, u, ng, d, s, t), 0)
    else
        # (F - SU)
        1 - _start_up_limit(m, u, ng, d, s, t)
    end
end

function constraint_unit_flow_capacity_tight_compact_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=subpath, t=t, t_next=t_next, case=case, part=part)
        for (u, ng, d) in indices(unit_capacity)
        for t in t_highest_resolution(
            m,
            Iterators.flatten(
                ((t for (u, t) in unit_time_indices(m; unit=u)), (t for (ng, t) in node_time_indices(m; node=ng)))
            )
        )
        for t_next in _t_next(m, u, t)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    units_on_indices(m; unit=u, t=[t_overlaps_t(m; t=t); t_next]),
                    unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_overlaps_t(m; t=t)),
                    _switch(
                        d; from_node=nonspin_units_started_up_indices, to_node=nonspin_units_shut_down_indices
                    )(m; unit=u, t=t_overlaps_t(m; t=t)),
                )
            )
        )
        for (subpath, parts_by_case) in _unit_capacity_constraint_subpaths(path, u, t)
        for (case, parts) in parts_by_case
        for part in parts
    )
end

function _t_next(m, u, t)
    t_next = unit_time_indices(m; unit=u, t=t_before_t(m; t_before=t))
    if isempty(t_next)
        # Nothing next, return a tuple with a dummy TimeSlice so things work,
        # but essentially it will be as if there is nothing next indeed.
        (TimeSlice(end_(t), end_(t)),)
    else
        (t for (u, t) in t_next)
    end
end

"""
    _unit_capacity_constraint_subpaths(path, u, t)

Split the given stochastic path into subpaths of successive scenarios where the outcome
of min_up_time(...) > duration(t) is the same.
"""
function _unit_capacity_constraint_subpaths(path, u, t)
    isempty(path) && return ()
    all_subpaths = []
    current_subpath = []
    last_mut_gt_dur = nothing
    t_flow_duration = end_(t) - start(t)
    for s in path
        mut = min_up_time(unit=u, stochastic_scenario=s, t=t, _default=nothing)
        mut = align_variable_duration_unit(mut, start(t))
        mut_gt_dur = mut === nothing || mut > t_flow_duration
        if last_mut_gt_dur !== nothing && mut_gt_dur !== last_mut_gt_dur
            # Outcome change, store current subpath and start a new one
            push!(all_subpaths, (current_subpath, _parts_by_case(last_mut_gt_dur)))
            current_subpath = [s]
        else
            # No change, just extend the current subpath
            push!(current_subpath, s)
        end
        last_mut_gt_dur = mut_gt_dur
    end
    push!(all_subpaths, (current_subpath, _parts_by_case(last_mut_gt_dur)))
    all_subpaths
end

function _parts_by_case(last_mut_gt_dur)
    if last_mut_gt_dur
        Dict(Object(:min_up_time_gt_time_step, :case) => (Object(:one, :part),)) 
    else
        Dict(Object(:min_up_time_le_time_step, :case) => (Object(:one, :part), Object(:two, :part))) 
    end
end

function constraint_unit_flow_capacity_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity)
        if has_online_variable(unit=u) || members(ng) != [ng]
        for t in t_highest_resolution(
            m,
            Iterators.flatten(
                ((t for (u, t) in unit_time_indices(m; unit=u)), (t for (ng, t) in node_time_indices(m; node=ng)))
            )
        )
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    units_on_indices(m; unit=u, t=t_overlaps_t(m; t=t)),
                    unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_overlaps_t(m; t=t)),
                )
            )
        )
    )
end

function _is_regular_node(n, d)
    !is_reserve_node(node=n) || (
        is_reserve_node(node=n)
        && _switch(d; to_node=upward_reserve, from_node=downward_reserve)(node=n)
        && !is_non_spinning(node=n)
    )
end
