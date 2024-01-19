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
In order to impose an upper limit on the maximum voltage angle at a node
the parameter [max\_voltage\_angle](@ref) can be specified which triggers the following constraint:

```math
\begin{aligned}
& \sum_{n \in ng} v^{node\_voltage\_angle}_{(n,s,t)} \geq p^{max\_voltage\_angle}_{(ng,s,t)} \\
& \forall ng \in indices(p^{max\_voltage\_angle}) \\
& \forall (s,t)
\end{aligned}
```
As indicated in the equation, the parameter [max\_voltage\_angle](@ref) can also be defined on a node group,
in order to impose an upper limit on the aggregated [node\_voltage\_angle](@ref) within one node group.

See also [max\_voltage\_angle](@ref).

"""
function add_constraint_max_node_voltage_angle!(m::Model)
    @fetch node_voltage_angle = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:max_node_voltage_angle] = Dict(
        (node=ng, stochastic_scenario=s, t=t) => @constraint(
            m,
            + expr_sum(
                + node_voltage_angle[ng, s, t]
                for (ng, s, t) in node_voltage_angle_indices(m; node=ng, stochastic_scenario=s, t=t);
                init=0,
            )
            <=
            + max_voltage_angle[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t)]
        )
        for (ng, s, t) in constraint_max_node_voltage_angle_indices(m)
    )
end

function constraint_max_node_voltage_angle_indices(m::Model)
    unique(
        (node=ng, stochastic_path=path, t=t)
        for (ng, s, t) in node_voltage_angle_indices(m; node=indices(max_voltage_angle))
        for path in active_stochastic_paths(m, s)
    )
end

"""
    constraint_max_node_voltage_angle_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:max_node_voltage_angle` constraint.

Uses stochastic path indices of the `node_voltage_angle` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_max_node_voltage_angle_indices_filtered(
    m::Model;
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_max_node_voltage_angle_indices(m))
end
