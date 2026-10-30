#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
   
The variable `unit_flow_reactive`, describing the injection and absorption of 
reactive power of generators, should be limited when the reactive flow capacity has
been specified. This takes place based on the number of units online (variable 
[units\_on](@ref var_units_on)). 
The constraint is enforced only if such variable is present. Note that setting 
[online\_variable\_type](@ref) to `linear` is not enough for this.

The constraint becomes

```math
\begin{aligned}
& 
    v^{unit\_flow\_reactive}_{(u,ng,d,s,t)} \cdot \left[ \neg p^{reserve\_active}_{(ng)} \right]\\

& \le \\
& p^{unit\_reactive\_capacity}_{(u,ng,d,s,t)} \cdot p^{availability\_factor}_{(u,s,t)} \cdot p^{capacity\_to\_flow\_conversion\_factor}_{(u,ng,d,s,t)}  \cdot v^{units\_on}_{(u,s,t)} \\

& \forall (u,ng,d) \in indices(p^{unit\_reactive\_capacity}) \\
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

"""
function add_constraint_unit_flow_capacity_reactive!(m::Model)
    _add_constraint!(m, :unit_flow_capacity_reactive, constraint_unit_flow_capacity_reactive_indices, 
        _build_constraint_unit_flow_capacity_reactive)
end

function _build_constraint_unit_flow_capacity_reactive(m, u, ng, d, s, t)
    @fetch unit_flow_reactive, units_on = m.ext[:spineopt].variables
    
    @build_constraint(
        sum(
            unit_flow_reactive[u, n, d, s, t_over] * overlap_duration(t_over, t)
            for (u, n, d, s, t_over) in unit_flow_reactive_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t)
            )
            if _is_regular_node(n, d);
            init=0,
        )
        <=
        + sum(
            units_on[u, s, t1]
            * min(duration(t1), duration(t))
            * availability_factor(m, unit=u, stochastic_scenario=s, t=t)
            * unit_capacity_reactive(m, unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * capacity_to_flow_conversion_factor(m, unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
            init=0,
        )      
    )
end

"""
    constraint_unit_flow_capacity_reactive_indices(m::Model)

    Produces the constraint indices for limiting reactive flows of units.

    Note: case with no online variable has not been checked.
"""
function constraint_unit_flow_capacity_reactive_indices(m::Model)
(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity_reactive)
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