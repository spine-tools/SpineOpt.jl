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
emissions, or other commodities (e.g., water, steel). The [unit_min_factor] and the [unit\_capacity](@ref) must be specified
for at least one [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship,
in order to trigger a constraint on the minimum commodity flows to this location in each time step.

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
& \ge \\
& p^{unit\_capacity}_{(u,ng,d,s,t)} \cdot p^{unit\_availability\_factor}_{(u,s,t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u,ng,d,s,t)} \\
& \cdot ( \\
& \qquad v^{units\_on}_{(u,s,t)} \\
& \forall (u,ng,d) \in indices(p^{unit\_capacity}) \\
& \forall (s,t)
\end{aligned}
```

!!! note
    The conversion factor [unit\_conv\_cap\_to\_flow](@ref) has a default value of `1`, but can be adjusted
    in case the unit of measurement for the capacity is different to the unit flows unit of measurement.

!!! note
    XXX

See also
[is\_reserve\_node](@ref),
[unit\_capacity](@ref),
[unit\_availability\_factor](@ref),
[unit\_conv\_cap\_to\_flow](@ref).
"""
function add_constraint_unit_min_flow!(m::Model)
        _add_constraint_unit_min_flow!(m)
end

function _add_constraint_unit_min_flow!(m::Model)
    _add_constraint!(
        m, :unit_min_flow, constraint_unit_min_flow_indices, _build_constraint_unit_min_flow
    )
end

function _build_constraint_unit_min_flow(m::Model, u, ng, d, s_path, t)
    @build_constraint(
        _term_unit_flow_var(m, u, ng, d, s_path, t) 
        >= 
        _term_flow_lower_limit(m, u, ng, d, s_path, t) 
        * _term_units_available(m, u, s_path, t)
    )
end

function _term_unit_flow_var(m, u, ng, d, s_path, t)
    @fetch unit_flow = m.ext[:spineopt].variables
    sum(
        get(unit_flow, (u, n, d, s, t_over), 0) * overlap_duration(t_over, t)
        for n in members(ng), s in s_path, t_over in t_overlaps_t(m; t=t)
        if _is_regular_node(n, d);
        init=0,
    )
end

function _term_flow_lower_limit(m, u, ng, d, s_path, t)
    sum(
        unit_flow_lower_limit(m, u, ng, d, s, t) * overlap_duration(t_over, t)
        for (u, s, t_over) in unit_stochastic_time_indices(
            m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
        );
        init=0,
    )
end

function _term_units_available(m, u, s_path, t)
    sum(
        units_invested_available[u, s, t1]
        for (u, s, t1) in units_invested_available_indices(
             m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
        );
        init=0,
    )
    + number_of_units(m; unit=u, stochastic_scenario=s_path, t=t, _default=_default_nb_of_units(u))
    - units_unavailable(m; unit=u, stochastic_scenario=s_path, t=t)
end

function constraint_unit_min_flow_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity) # unit_flow_lower_limit or _unit_flow_lower_limit
        if members(ng) != [ng]
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
                    unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_overlaps_t(m; t=t)),
                )
            )
        )
    )
end
