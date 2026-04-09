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
[unit\_flow](@ref) is constrained to be the sum of all operating segment variables, [unit\_flow\_op](@ref)

```math
\begin{aligned}
& v^{unit\_flow}_{(u, n, d, s, t)} = \sum_{op=1}^{\left\|p^{operating\_points}_{(u,n,d)}\right\|} v^{unit\_flow\_op}_{(u, n, d, op, s, t)} \\
& \forall (u,n,d) \in indices(p^{operating\_points}) \\
& \forall (s,t)
\end{aligned}
```

See also [operating\_points](@ref).
"""
function add_constraint_unit_flow_op_sum!(m::Model)
    _add_constraint!(m, :unit_flow_op_sum, constraint_unit_flow_op_sum_indices, _build_constraint_unit_flow_op_sum)
end

function _build_constraint_unit_flow_op_sum(m::Model, u, n, d, s, t)
    @fetch unit_flow_op, unit_flow = m.ext[:spineopt].variables
    @build_constraint(
        + unit_flow[u, n, d, s, t]
        ==
        + sum(unit_flow_op[u, n, d, op, s, t] for op in 1:length(operating_points(unit=u, node=n, direction=d)); init=0)
    )
end

function constraint_unit_flow_op_sum_indices(m::Model)
    (
        (unit=u, node=n, direction=d, stochastic_scenmario=s, t=t)
        for (u, n, d) in indices(operating_points)
        for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=n, direction=d)
    )
end
