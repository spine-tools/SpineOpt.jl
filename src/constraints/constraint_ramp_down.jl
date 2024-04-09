#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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

@doc raw"""
Limit the decrease of [unit\_flow](@ref) over a time period of one [duration\_unit](@ref) according
to the [shut\_down\_limit](@ref) and [ramp\_down\_limit](@ref) parameter values.

```math
\begin{aligned}
& \sum_{
        n \in ng
}
v^{unit\_flow}_{(u,n,d,s,t-1)} \cdot \left[ \neg p^{is\_reserve\_node}_{(n)} \right] \\
& - \sum_{
        n \in ng
}
v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[ \neg p^{is\_reserve\_node}_{(n)} \right] \\
& + \sum_{
        n \in ng
}
v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[ p^{is\_reserve\_node}_{(n)} \land p^{downward\_reserve}_{(n)} \right] \\
& \le ( \\
& \qquad \left(p^{shut\_down\_limit}_{(u,ng,d,s,t)} - p^{minimum\_operating\_point}_{(u,ng,d,s,t)} - p^{ramp\_down\_limit}_{(u,ng,d,s,t)}\right) \cdot v^{units\_shut\_down}_{(u,s,t)} \\
& \qquad + \left(p^{minimum\_operating\_point}_{(u,ng,d,s,t)} + p^{ramp\_down\_limit}_{(u,ng,d,s,t)}\right) \cdot v^{units\_on}_{(u,s,t-1)} \\
& \qquad - p^{minimum\_operating\_point}_{(u,ng,d,s,t)} \cdot v^{units\_on}_{(u,s,t)} \\
& ) \cdot p^{unit\_capacity}_{(u,ng,d,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,ng,d,s,t)} \cdot \Delta t \\
& \forall (u,ng,d) \in indices(p^{ramp\_down\_limit}) \cup indices(p^{shut\_down\_limit}) \\
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

See also
[is\_reserve\_node](@ref),
[downward\_reserve](@ref),
[unit\_capacity](@ref),
[unit\_conv\_cap\_to\_flow](@ref),
[ramp\_down\_limit](@ref),
[shut\_down\_limit](@ref),
[minimum\_operating\_point](@ref).
"""
function add_constraint_ramp_down!(m::Model)
    @fetch units_on, units_shut_down, unit_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:ramp_down] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s_path, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_before, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_before)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            - sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_after)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            + sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_after)
                )
                if is_reserve_node(node=n)
                && _switch(d; to_node=downward_reserve, from_node=upward_reserve)(node=n)
                && !is_non_spinning(node=n);
                init=0,
            )
            <=
            + (
                + sum(
                    + (
                        + _shut_down_limit(u, ng, d, s, t0, t_after)
                        - _minimum_operating_point(u, ng, d, s, t0, t_after)
                        - _ramp_down_limit(u, ng, d, s, t0, t_after)
                    )
                    * _unit_flow_capacity(u, ng, d, s, t0, t_after)
                    * units_shut_down[u, s, t]
                    * duration(t)
                    - _minimum_operating_point(u, ng, d, s, t0, t_after)
                    * _unit_flow_capacity(u, ng, d, s, t0, t_after)
                    * units_on[u, s, t]
                    * duration(t)
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_after);
                    init=0
                )
                + sum(
                    + (_minimum_operating_point(u, ng, d, s, t0, t_after) + _ramp_down_limit(u, ng, d, s, t0, t_after))
                    * _unit_flow_capacity(u, ng, d, s, t0, t_after)
                    * units_on[u, s, t]
                    * duration(t)
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_before);
                    init=0
                )
            )
            * duration(t_after)
        )
        for (u, ng, d, s_path, t_before, t_after) in constraint_ramp_down_indices(m)
    )
end

function _ramp_down_limit(u, ng, d, s, t0, t)
    ramp_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function constraint_ramp_down_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in Iterators.flatten((indices(ramp_down_limit), indices(shut_down_limit)))
        for (u, t_before, t_after) in unit_dynamic_time_indices(m; unit=u)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    unit_flow_indices(m; unit=u, node=ng, direction=d, t=_overlapping_t(m, t_before, t_after)),
                    units_on_indices(m; unit=u, t=[t_before, t_after]),
                )
            )
        )
    )
end

"""
    constraint_ramp_down_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:ramp_down` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ramp_down_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    function f(ind)
        _index_in(
            ind;
            unit=unit,
            node=node,
            direction=direction,
            stochastic_path=stochastic_path,
            t_before=t_before,
            t_after=t_after,
        )
    end

    filter(f, constraint_ramp_down_indices(m))
end
