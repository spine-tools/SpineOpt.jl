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

Limit the maximum number of each activated segment `unit_flow_op_active` cannot be higher than the number of
online units. This constraint is activated only when parameter [ordered\_unit\_flow\_op](@ref) is set `true`.

```math
\begin{aligned}
& v^{unit\_flow\_op\_active}_{(u,n,d,op,s,t)} \leq v^{units\_on}_{(u,s,t)} \\
& \forall (u,n,d) \in indices(p^{operating\_points}): p^{ordered\_unit\_flow\_op}_{(u,n,d)} \\
& \forall op \in \{ 1, \ldots, \left\|p^{operating\_points}_{(u,n,d)}\right\| \} \\
& \forall (s,t)
\end{aligned}
```

See also [operating\_points](@ref), [ordered\_unit\_flow\_op](@ref).
"""
function add_constraint_operating_point_bounds!(m::Model)
    _add_constraint!(
        m, :operating_point_bounds, constraint_operating_point_bounds_indices, _build_constraint_operating_point_bounds
    )
end

function _build_constraint_operating_point_bounds(m::Model, u, n, d, op, s_path, t)
    @fetch unit_flow_op_active = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            unit_flow_op_active[u, n, d, op, s, t]
            for (u, n, d, op, s, t) in unit_flow_op_active_indices(
                m; unit=u, node=n, direction=d, i=op, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        <= 
        sum(
            _get_units_on(m, u, s, t)
            for (u, s, t) in unit_stochastic_time_indices(
                m; unit=u, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
    )
end

function constraint_operating_point_bounds_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, i=i, stochastic_path=path, t=t)
        # NOTE: a stochastic_path is an array consisting of stochastic scenarios, e.g. [s1, s2]
        for (u, ng, d, i, _s, _t) in unit_flow_op_active_indices(m)
        for (t, path) in t_lowest_resolution_path(
            m, unit_flow_op_indices(m; unit=u, node=ng, direction=d, i=i), units_on_indices(m; unit=u)
        )
    )
end
