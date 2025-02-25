#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
In order to impose an upper limit on the maximum pressure at a node
the parameter [pressure\_max](@ref) can be specified which triggers the following constraint:

```math
\sum_{n \in ng} v^{node\_pressure}_{(n,s,t)} \leq p^{pressure\_max}_{(ng,s,t)}
\quad \forall (ng) \in indices(p^{pressure\_max}), \, \forall (s,t)
```

As indicated in the equation, the parameter [pressure\_max](@ref) can also be defined on a node group,
in order to impose an upper limit on the aggregated [node\_pressure](@ref) within one node group.

See also [pressure\_max](@ref).
"""
function add_constraint_max_node_pressure!(m::Model)
    _add_constraint!(m, :max_node_pressure, constraint_max_node_pressure_indices, _build_constraint_max_node_pressure)
end

function _build_constraint_max_node_pressure(m::Model, ng, s_path, t)
    @fetch node_pressure = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            + node_pressure[n, s, t]
            - pressure_max(m; node=ng, stochastic_scenario=s, t=t)
            for (n, s, t) in node_pressure_indices(m; node=ng, stochastic_scenario=s_path, t=t);
            init=0,
        )
        <=
        0
    )
end

function constraint_max_node_pressure_indices(m::Model)
    ((node=ng, stochastic_path=[s], t=t) for (ng, s, t) in node_pressure_indices(m; node=indices(pressure_max)))
end

"""
    constraint_max_node_pressure_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:max_node_pressure` constraint.

Uses stochastic path indices of the `node_pressure` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_max_node_pressure_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_max_node_pressure_indices(m))
end
