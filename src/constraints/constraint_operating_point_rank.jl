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
Rank operating segments by enforcing that the variable `unit_flow_op_active` of operating point `i` can only be active 
if previous operating point `i-1` is also active. The first segment does not need this constraint.

```math
\begin{aligned}
& v^{unit\_flow\_op\_active}_{(u,n,d,op,s,t)} \leq v^{unit\_flow\_op\_active}_{(u,n,d,op-1,s,t)} \\
& \forall (u,n,d) \in indices(p^{operating\_points}): p^{ordered\_unit\_flow\_op}_{(u,n,d)} \\
& \forall op \in \{ 2, \ldots, \left\|p^{operating\_points}_{(u,n,d)}\right\| \} \\
& \forall (s,t)
\end{aligned}
```

See also [operating\_points](@ref), [ordered\_unit\_flow\_op](@ref).
"""
function add_constraint_operating_point_rank!(m::Model)
    _add_constraint!(
        m, :operating_point_rank, constraint_operating_point_rank_indices, _build_constraint_operating_point_rank
    )
end

function _build_constraint_operating_point_rank(m::Model, u, n, d, op, s, t)
    @fetch unit_flow_op_active = m.ext[:spineopt].variables
    @build_constraint(unit_flow_op_active[u, n, d, op, s, t] <= unit_flow_op_active[u, n, d, op - 1, s, t])
end

function constraint_operating_point_rank_indices(m::Model)
    (
        (unit=u, node=n, direction=d, i=op, stochastic_scenario=s, t=t)
        for (u, n, d, op, s, t) in unit_flow_op_active_indices(m)
        if (op > 1)
    )
end
