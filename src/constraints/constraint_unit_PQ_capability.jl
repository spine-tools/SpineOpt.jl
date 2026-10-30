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

To take into account the capability of generators to simultaneously inject real
power and inject or absorb reactive power. Because the shape of the capability region
can vary, the user is given the chance to approximate it by a polygon. The faces of the polygon 
are defined by coefficient for real power  $p^{capability\_curve\_P}$ and constant $p^{capability\_curve\_C}$.
The coefficient for reactive power is 1.0. One can define several such faces.
Constraint is based on the number of units online (units_on). The constraint is enforced only if
such variable is present. 

```math
\begin{aligned}
& 
    \frac{v^{unit\_flow}_{(u,ng,to\_node,s,t)} }{p^{capacity\_per\_unit}_{(u,ng,to\_node,s,t)}}\cdot \left[ \neg p^{reserve\_active}_{(ng)} \right] \cdot p^{capability\_curve\_P}_{(u,ng,d,s,t,i)}\\ 
& + \frac{v^{unit\_flow\_reactive}_{(u,ng,d,s,t)}}{p^{unit\_capacity\_reactive}_{(u,ng,d,s,t)} } \cdot \left[ \neg p^{reserve\_active}_{(ng)} \right] \\
& \le \\
&   v^{units\_on}_{(u,s,t)} \cdot p^{capability\_curve\_C}_{(u,ng,d,s,t,i)} \cdot p^{availability\_factor}_{(u,s,t)} \cdot p^{capacity\_to\_flow\_conversion\_factor}_{(u,ng,d,s,t)} \\

& \forall (u,ng,d,i) \in indices(p^{unit\_reactive\_capacity}) \\
& \forall (s,t)
\end{aligned}
```
where index $i$ refers to the different bounding lines of the capability region.

"""
function add_constraint_unit_pq_capability!(m::Model)
    _add_constraint!(m, :unit_pq_capability, constraint_unit_pq_capability_indices, 
        _build_constraint_unit_pq_capability)
end

function _build_constraint_unit_pq_capability(m, u, ng, d, s, t, ce)
    @fetch unit_flow_reactive, unit_flow, units_on = m.ext[:spineopt].variables
    
    @build_constraint(
        sum(
            unit_flow_reactive[u, n, d, s, t_over] 
            / unit_capacity_reactive(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t_over, _default=1.0)
            * overlap_duration(t_over, t)
            for (u, n, d, s, t_over) in unit_flow_reactive_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t)
            )
            if _is_regular_node(n, d);
            init=0,
        )
        + sum(
            unit_flow[u, n, dP, s, t_over] 
            / capacity_per_unit(m; unit=u, node=n, direction=dP, stochastic_scenario=s, t=t_over, _default=1.0)
            * overlap_duration(t_over, t)
            * pq_capability_curve_P_coef(m, unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_over, i=ce)
            for (u, n, dP, s, t_over) in unit_flow_indices(
                m; unit=u, node=ng, direction=direction(:to_node), stochastic_scenario=s, t=t_overlaps_t(m; t=t)
            )
            if _is_regular_node(n, d);
            init=0,
        )
        <=
        + sum(
            units_on[u, s, t1]
            * min(duration(t1), duration(t))
            * availability_factor(m, unit=u, stochastic_scenario=s, t=t)
            * pq_capability_curve_constant(m, unit=u, node=ng, direction=d, stochastic_scenario=s, t=t, i=ce)
            * capacity_to_flow_conversion_factor(m, unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
            init=0,
        )      
    )
end


function constraint_unit_pq_capability_indices(m::Model)
(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t, capability_edge=c)
        for (u, ng, d) in indices(pq_capability_curve_constant)
            if has_online_variable(unit=u) && has_acflow(node=ng)
        for c in 1:length(pq_capability_curve_constant(unit=u, node=ng, direction=d))
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