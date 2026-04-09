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
If the segments of a `unit_flow`, i.e. `unit_flow_op` is not ordered according to the rank of
the `unit_flow`'s [operating\_points](@ref) (parameter [ordered\_unit\_flow\_op](@ref) is `false`),
the operating segment variable `unit_flow_op` is only bounded by the difference
between successive [operating\_points](@ref) adjusted for available capacity.
If the order is enforced on the segments (parameter [ordered\_unit\_flow\_op](@ref) is `true`),
`unit_flow_op` can only be active if the segment is active (variable [unit\_flow\_op\_active](@ref) is `true`)
besides being bounded by the segment capacity.

```math
\begin{aligned}
& v^{unit\_flow\_op}_{(u, n, d, op, s, t)} \\
& \leq p^{unit\_capacity}_{(u, n, d, s, t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u, n, d, s, t)} \cdot p^{unit\_availability\_factor}_{(u, s, t)} \\
& \cdot \left( p^{operating\_points}_{(u, n, d, op, s, t)}
- \begin{cases}       
   p^{operating\_points}_{(u, n, op-1, s, t)} & \text{if } op > 1\\
   0 & \text{otherwise}\\
\end{cases} \right) \\
& \cdot \begin{cases}
    v^{unit\_flow\_op\_active}_{(u,n,d,op,s,t)} & \text{if } p^{ordered\_unit\_flow\_op}_{(u,s,t)} \\
    v^{units\_on}_{(u,s,t)} & \text{otherwise}\\
\end{cases} \\
& \forall (u,n,d) \in indices(p^{unit\_capacity}) \cup indices(p^{operating\_points}) \\
& \forall op \in \{ 1, \ldots, \left\|p^{operating\_points}_{(u,n,d)}\right\| \} \\
& \forall (s,t)
\end{aligned}
```

See also
[unit\_capacity](@ref),
[unit\_conv\_cap\_to\_flow](@ref),
[unit\_availability\_factor](@ref),
[operating\_points](@ref),
[ordered\_unit\_flow\_op](@ref).
"""
function add_constraint_unit_flow_op_bounds!(m::Model)
    _add_constraint!(
        m, :unit_flow_op_bounds, constraint_unit_flow_op_bounds_indices, _build_constraint_unit_flow_op_bounds
    )
end

function _build_constraint_unit_flow_op_bounds(m::Model, u, n, d, op, s, t)
    @fetch unit_flow_op, unit_flow_op_active = m.ext[:spineopt].variables
    @build_constraint(
        + unit_flow_op[u, n, d, op, s, t]
        <=
        (
            ordered_unit_flow_op(unit=u, node=n, direction=d, _default=false) ? 
            unit_flow_op_active[u, n, d, op, s, t] : _get_units_on(m, u, s, t)
        )
        * (
            + operating_points(m; unit=u, node=n, direction=d, stochastic_scenario=s, i=op)
            - ((op > 1) ? operating_points(m; unit=u, node=n, direction=d, stochastic_scenario=s, i=(op - 1)) : 0)
        )
        * unit_flow_capacity(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
    )
end

function constraint_unit_flow_op_bounds_indices(m::Model)
    (
        (unit=u, node=n, direction=d, i=op, stochastic_scenario=s, t=t)
        for (u, n, d) in indices(unit_capacity)
        for (u, n, d, op, s, t) in unit_flow_op_indices(m; unit=u, node=n, direction=d)
    )
end
