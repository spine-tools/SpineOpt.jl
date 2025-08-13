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
The minimum operating point of a unit is based on the [unit\_flow](@ref)s of
input or output nodes/node groups.

```math
\begin{aligned}
& \sum_{
        n \in ng
}
v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[\neg p^{is\_reserve\_node}_{(n)}\right]
- \sum_{
        n \in ng
}
v^{unit\_flow}_{(u,n,d,s,t)} \cdot \left[p^{is\_reserve\_node}_{(n)} \land p^{downward\_reserve}_{(n)}\right] \\
& \ge p^{minimum\_operating\_point}_{(u,ng,d,s,t)} \cdot p^{unit\_capacity}_{(u,ng,d,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,ng,d,s,t)} \\
& \cdot \left( v^{units\_on}_{(u,s,t)}
- \sum_{
    n \in ng
} v^{nonspin\_units\_shut\_down}_{(u,n,s,t)} \right) \\
& \forall (u,ng,d) \in indices(p^{minimum\_operating\_point}) \\
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
    The above formulation is valid for flows going from a unit to a node (i.e., output flows).
    For flows going from a node to a unit (i.e., input flows) the direction of the reserves is switched
    (downwards becomes upwards, non-spinning units shut-down becomes non-spinning units started-up).
    The details are omitted for brevity.

See also
[is\_reserve\_node](@ref),
[downward\_reserve](@ref),
[is\_non\_spinning](@ref),
[minimum\_operating\_point](@ref),
[unit\_capacity](@ref),
[unit\_conv\_cap\_to\_flow](@ref)
"""
function add_constraint_minimum_operating_point!(m::Model)
    _add_constraint!(
        m,
        :minimum_operating_point,
        constraint_minimum_operating_point_indices,
        _build_constraint_minimum_operating_point,
    )
end

function _build_constraint_minimum_operating_point(m::Model, u, ng, d, s_path, t)
    @fetch unit_flow, nonspin_units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + unit_flow[u, n, d, s, t_short] * duration(t_short)
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_in_t(m, t_long=t)
            )
            if !is_reserve_node(node=n);
            init=0,
        )
        - sum(
            + unit_flow[u, n, d, s, t_short] * duration(t_short)
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_in_t(m, t_long=t)
            )
            if is_reserve_node(node=n) && _switch(d; to_node=downward_reserve, from_node=upward_reserve)(node=n);
            init=0,
        )
        >=
        + sum(
            (
                + _get_units_on(m, u, s, t_over)
                - sum(
                    _switch(
                        d; from_node=nonspin_units_started_up, to_node=nonspin_units_shut_down
                    )[u, n, s, t]
                    for (u, n, s, t) in _switch(
                        d; from_node=nonspin_units_started_up_indices, to_node=nonspin_units_shut_down_indices
                    )(m; unit=u, node=ng, stochastic_scenario=s, t=t_over);
                    init=0
                )
            )
            * min(duration(t), duration(t_over))
            * minimum_operating_point(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * unit_capacity(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * unit_conv_cap_to_flow(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            for (u, s, t_over) in unit_stochastic_time_indices(
                m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
            );
            init=0,
        )
    )
end

function constraint_minimum_operating_point_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(minimum_operating_point)
        if minimum_operating_point(; unit=u, node=ng, direction=d) != 0
        for (t, path) in t_lowest_resolution_path(
            m, unit_flow_indices(m; unit=u, node=ng, direction=d), units_on_indices(m; unit=u)
        )
    )
end

"""
    constraint_minimum_operating_point_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:minimum_operating_point` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`unit_flow` and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_minimum_operating_point_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_minimum_operating_point_indices(m))
end
