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
Limit the increase of [unit\_flow](@ref) over a time period of one [duration\_unit](@ref) according
to the [start\_up\_limit](@ref) and [ramp\_up\_limit](@ref) parameter values.

```math
\begin{aligned}
& \frac{\sum_{n \in ng, \: t' \in overlapping(t)}
v^{unit\_flow}_{(u,n,d,s,t')} \cdot \Delta(t'\cap t) \cdot \left[ \neg p^{is\_reserve\_node}_{(n)} \right] }{\Delta(overlapping(t))} \\

& - \frac{\sum_{n \in ng, \: t' \in overlapping(t-1)}
v^{unit\_flow}_{(u,n,d,s,t')} \cdot \Delta(t'\cap t-1)  \cdot \left[ \neg p^{is\_reserve\_node}_{(n)} \right] }{\Delta(overlapping(t-1))} \\

& + \frac{\sum_{
        n \in ng, \: t' \in overlapping(t)}
v^{unit\_flow}_{(u,n,d,s,t')} \cdot \Delta(t'\cap t) \cdot \left[ p^{is\_reserve\_node}_{(n)} \land p^{upward\_reserve}_{(n)} \right]}{\Delta(overlapping(t))} \\

& \le ( \\

& \qquad \frac{\sum_{t' \in overlapping(t)}\left(p^{start\_up\_limit}_{(u,ng,d,s,t')} - p^{minimum\_operating\_point}_{(u,ng,d,s,t')}
\right) \cdot v^{units\_started\_up}_{(u,s,t)} \cdot \Delta(t'\cap t)}{\Delta(overlapping(t))}\\

& \qquad + 
\frac{\sum_{t' \in overlapping(t)} \left( p^{minimum\_operating\_point}_{(u,ng,d,s,t)}
 \cdot v^{units\_on}_{(u,s,t')} \cdot \Delta(t'\cap t) \right) }{\Delta(overlapping(t))}   \\

& \qquad - 
\frac{\sum_{t' \in overlapping(t-1)} \left( p^{minimum\_operating\_point}_{(u,ng,d,s,t)}
 \cdot v^{units\_on}_{(u,s,t')} \cdot \Delta(t'\cap t-1) \right) }{\Delta(overlapping(t))}   \\

& \qquad + \frac{1}{2} \cdot
\sum_{t' \in overlapping(t)} \left( p^{ramp\_up\_limit}_{(u,ng,d,s,t)}
 \cdot v^{units\_on}_{(u,s,t')} \cdot \Delta(t'\cap t) \right)    \\

& \qquad + \frac{1}{2} \cdot
\sum_{t' \in overlapping(t-1)} \left( p^{ramp\_up\_limit}_{(u,ng,d,s,t)}
 \cdot v^{units\_on}_{(u,s,t')} \cdot \Delta(t'\cap t-1) \right)    \\

& ) \cdot p^{unit\_capacity}_{(u,ng,d,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,ng,d,s,t)} \\


& \forall (u,ng,d) \in indices(p^{ramp\_up\_limit}) \cup indices(p^{start\_up\_limit}) \\
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

Here``overlapping(t)`` is the set of time slices which overlap ``t``, and
``t'\cap t`` is the intersection of time slices ``t'`` and ``t``. 

See also
[is\_reserve\_node](@ref),
[upward\_reserve](@ref),
[unit\_capacity](@ref),
[unit\_conv\_cap\_to\_flow](@ref),
[ramp\_up\_limit](@ref),
[start\_up\_limit](@ref),
[minimum\_operating\_point](@ref).
"""
function add_constraint_ramp_up!(m::Model)
    _add_constraint!(m, :ramp_up, constraint_ramp_up_indices, _build_constraint_ramp_up)
end

function _build_constraint_ramp_up(m::Model, u, ng, d, s_path, t_before, t_after)
    @fetch units_on, units_started_up, unit_flow = m.ext[:spineopt].variables

    # auxiliary functions for calculating time durations
    overlap_duration_flow = t1 -> overlap_duration(t1, 
                                    TimeSlice(minimum( max(start(t1), start(t))
                                    for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=ng, 
                                        direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t1))
                                        ),
                                    maximum( min(end_(t1), end_(t))
                                    for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=ng, 
                                        direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t1))
                                        ) 
                                    )   
                                )
    
    overlap_duration_units_on = t1 -> sum(overlap_duration(t1, t)
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t1);
                init=0)
    
    overlap_duration_switched = t1 -> sum(overlap_duration(t1, t)
                for (u, s, t) in units_switched_indices(m; unit=u, stochastic_scenario=s_path, t=t1);
                init=0)    

    @build_constraint(
        + sum(
            + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
            for (u, n, d, s, t) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_after)
            )
            if !is_reserve_node(node=n);
            init=0,
        ) / overlap_duration_flow(t_after)
        - sum(
            + unit_flow[u, n, d, s, t] * overlap_duration(t_before, t)
            for (u, n, d, s, t) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_before)
            )
            if !is_reserve_node(node=n);
            init=0,
        ) / overlap_duration_flow(t_before)
        + sum(
            + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
            for (u, n, d, s, t) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_after)
            )
            if is_reserve_node(node=n)
            && _switch(d; to_node=upward_reserve, from_node=downward_reserve)(node=n)
            && !is_non_spinning(node=n);
            init=0,
        ) / overlap_duration_flow(t_after)
        <=
        (
            + sum(  (
                    + _start_up_limit(m, u, ng, d, s, t_after)
                    - _minimum_operating_point(m, u, ng, d, s, t_after)
                    )
                * _unit_flow_capacity(m, u, ng, d, s, t_after)
                * units_started_up[u, s, t]
                * overlap_duration(t_after, t)
                for (u, s, t) in units_switched_indices(m; unit=u, stochastic_scenario=s_path, t=t_after);
                init=0,
            ) / overlap_duration_switched(t_after)
            + sum(
                + _minimum_operating_point(m, u, ng, d, s, t_after)
                * _unit_flow_capacity(m, u, ng, d, s, t_after)
                * units_on[u, s, t]
                * overlap_duration(t_after, t)
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_after);
                init=0,
            ) / overlap_duration_units_on(t_after)
            - sum(
                + _minimum_operating_point(m, u, ng, d, s, t_after)
                * _unit_flow_capacity(m, u, ng, d, s, t_after)
                * units_on[u, s, t]
                * overlap_duration(t_before, t)
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_before);
                init=0,
            ) / overlap_duration_units_on(t_before)
            + sum(
                + _ramp_up_limit(m, u, ng, d, s, t_after)
                * _unit_flow_capacity(m, u, ng, d, s, t_after)
                * units_on[u, s, t]
                * overlap_duration(t_before, t)
                * 0.5
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_before);
                init=0,
            )
            + sum(
                + _ramp_up_limit(m, u, ng, d, s, t_after)
                * _unit_flow_capacity(m, u, ng, d, s, t_after)
                * units_on[u, s, t]
                * overlap_duration(t_after, t)
                * 0.5
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_after);
                init=0,
            )
        )
    )
end

function _ramp_up_limit(m, u, ng, d, s, t)
    ramp_up_limit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t, _default=1)
end

function constraint_ramp_up_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in Iterators.flatten((indices(ramp_up_limit), indices(start_up_limit)))
        for (u, t_before, t_after) in unit_dynamic_time_indices(m; unit=u)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    unit_flow_indices(m; unit=u, node=ng, direction=d, t=_overlapping_t(m, t_before, t_after)),
                    units_on_indices(m; unit=u, t=[t_before; t_after]),
                )
            )
        )
    )
end

"""
    constraint_ramp_up_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:ramp_up` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ramp_up_indices_filtered(
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

    filter(f, constraint_ramp_up_indices(m))
end
