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
Enforce the operating point flow variable `unit_flow_op` at operating point `i` to use its full capacity
if the subsequent operating point `i+1` is active if parameter [ordered\_unit\_flow\_op](@ref) is set `true`.
The last segment does not need this constraint.

```math
\begin{aligned}
& v^{unit\_flow\_op}{(u, n, d, op, s, t)} \\
& \geq p^{unit\_capacity}_{(u, n, d, s, t)} \cdot p^{unit\_conv\_cap\_to\_flow}_{(u, n, d, s, t)} \\
& \cdot \left(p^{operating\_points}_{(u, n, op, s, t)} - \begin{cases}       
   p^{operating\_points}_{(u, n, op-1, s, t)} & \text{if } op > 1 \\
   0 & \text{otherwise} \\
\end{cases} \right) \\
& \cdot v^{unit\_flow\_op\_active}_{(u, n, d, op+1, s, t)} \\
& \forall (u,n,d) \in indices(p^{unit\_capacity}) \cup indices(p^{operating\_points}): p^{ordered\_unit\_flow\_op}_{(u,n,d)} \\
& \forall op \in \{ 1, \ldots, \left\|p^{operating\_points}_{(u,n,d)}\right\| - 1\} \\
& \forall (s,t)
\end{aligned}
```

See also
[unit\_capacity](@ref),
[unit\_conv\_cap\_to\_flow](@ref),
[operating\_points](@ref),
[ordered\_unit\_flow\_op](@ref).
"""
function add_constraint_unit_flow_op_rank!(m::Model)
    _add_constraint!(m, :unit_flow_op_rank, constraint_unit_flow_op_rank_indices, _build_constraint_unit_flow_op_rank)
end

function _build_constraint_unit_flow_op_rank(m::Model, u, n, d, op, s, t)
    @fetch unit_flow_op, unit_flow_op_active = m.ext[:spineopt].variables
    @build_constraint(
        + unit_flow_op[u, n, d, op, s, t]
        >=
        (
            + operating_points(m; unit=u, node=n, direction=d, stochastic_scenario=s, i=op)
            - ((op > 1) ? operating_points(m; unit=u, node=n, direction=d, stochastic_scenario=s, i=(op - 1)) : 0)
        )
        * unit_flow_capacity(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        * unit_flow_op_active[u, n, d, op + 1, s, t]
    )
end

function constraint_unit_flow_op_rank_indices(m::Model)
    (
        (unit=u, node=n, direction=d, i=op, stochastic_scenario=s, t=t)
        for (u, n, d) in indices(unit_capacity)
        for (u, n, d, op, s, t) in unit_flow_op_active_indices(m; unit=u, node=n, direction=d)
        if op < lastindex(operating_points(unit=u, node=n, direction=d))
        # the partial unit flow at the last operating point does not need this constraint.
    )
end
