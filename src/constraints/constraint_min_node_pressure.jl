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
In order to impose a lower limit on the pressure at a node the parameter [min\_node\_pressure](@ref)
can be specified which triggers the following constraint:

```math
\sum_{n \in ng} v^{node\_pressure}_{(n,s,t)} \geq p^{min\_node\_pressure}_{(ng,s,t)}
\quad \forall (ng) \in indices(p^{min\_node\_pressure}), \, \forall (s,t)
```

As indicated in the equation, the parameter [min\_node\_pressure](@ref) can also be defined on a node group,
in order to impose a lower limit on the aggregated [node\_pressure](@ref) within one node group.

See also [min\_node\_pressure](@ref).
"""
function add_constraint_min_node_pressure!(m::Model)
    _add_constraint!(m, :min_node_pressure, constraint_min_node_pressure_indices, _build_constraint_min_node_pressure)
end

function _build_constraint_min_node_pressure(m::Model, ng, s_path, t)
    @fetch node_pressure = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            + node_pressure[ng, s, t]
            - min_node_pressure(m; node=ng, stochastic_scenario=s, t=t)
            for (ng, s, t) in node_pressure_indices(m; node=ng, stochastic_scenario=s_path, t=t);
            init=0,
        )
        >=
        0
    )
end

function constraint_min_node_pressure_indices(m::Model)
    ((node=ng, stochastic_path=[s], t=t) for (ng, s, t) in node_pressure_indices(m; node=indices(min_node_pressure)))
end

"""
    constraint_min_node_pressure_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:min_node_pressure` constraint.

Uses stochastic path indices of the `node_pressure` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_min_node_pressure_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_node_pressure_indices(m))
end
