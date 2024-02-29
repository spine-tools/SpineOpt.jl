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
To impose a limit on the cumulative amount of certain commodity flows,
a cumulative bound can be set by defining one of the following parameters:
* [max\_total\_cumulated\_unit\_flow\_from\_node](@ref)
* [min\_total\_cumulated\_unit\_flow\_from\_node](@ref)
* [max\_total\_cumulated\_unit\_flow\_to\_node](@ref)
* [min\_total\_cumulated\_unit\_flow\_to\_node](@ref)

A maximum cumulated flow restriction can for example be used to limit emissions or consumption of a certain commodity.


```math
\begin{aligned}
& \sum_{u \in ug, n \in ng} v^{unit\_flow}_{(u,n,d,s,t)} \leq p^{max\_total\_cumulated\_unit\_flow\_from\_node}_{(ug,ng,d)} \\
& \forall (ug,ng,d) \in indices(p^{max\_total\_cumulated\_unit\_flow\_from\_node}), \, \forall s \\
& \sum_{u \in ug, n \in ng} v^{unit\_flow}_{(u,n,d,s,t)} \geq p^{min\_total\_cumulated\_unit\_flow\_from\_node}_{(ug,ng,d)} \\
& \forall (ug,ng,d) \in indices(p^{min\_total\_cumulated\_unit\_flow\_from\_node}), \, \forall s \\
& \sum_{u \in ug, n \in ng} v^{unit\_flow}_{(u,n,d,s,t)} \leq p^{max\_total\_cumulated\_unit\_flow\_to\_node}_{(ug,ng,d)} \\
& \forall (ug,ng,d) \in indices(p^{max\_total\_cumulated\_unit\_flow\_to\_node}), \, \forall s \\
& \sum_{u \in ug, n \in ng} v^{unit\_flow}_{(u,n,d,s,t)} \geq p^{min\_total\_cumulated\_unit\_flow\_to\_node}_{(ug,ng,d)} \\
& \forall (ug,ng,d) \in indices(p^{min\_total\_cumulated\_unit\_flow\_to\_node}), \, \forall s \\
\end{aligned}
```

See also
[max\_total\_cumulated\_unit\_flow\_from\_node](@ref),
[min\_total\_cumulated\_unit\_flow\_from\_node](@ref),
[max\_total\_cumulated\_unit\_flow\_to\_node](@ref),
[min\_total\_cumulated\_unit\_flow\_to\_node](@ref).
"""
function add_constraint_total_cumulated_unit_flow!(m::Model, bound, sense)
    # TODO: How to turn this one into stochastical one? Path indexing over the whole `unit_group`?
    @fetch unit_flow = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[bound.name] = Dict(
        (unit=ug, node= ng, stochastic_path = s) => sense_constraint(
            m,
            + sum(
                unit_flow[u, n, d, s, t] * duration(t) # * node_stochastic_weight[(node=n, stochastic_scenario=s)]
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=ug, node = ng, direction=d, stochastic_scenario = s
                );
                init = 0
            ),
            sense,
            + bound(unit=ug, node=ng, direction=d)
            # TODO Should this be time-varying, and stochastical?
        )
        for (ug, ng, d, s) in constraint_total_cumulated_unit_flow_indices(m, bound)
    )
end

function constraint_total_cumulated_unit_flow_indices(m::Model, bound)
    unique(
        (unit=ug, node=ng, direction=d, stochastic_path=s)
        for (ug, ng, d) in indices(bound)
        for s in active_stochastic_paths(m, unit_flow_indices(m, direction=d, unit=ug, node=ng))
    )
end

function add_constraint_max_total_cumulated_unit_flow_from_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m, max_total_cumulated_unit_flow_from_node, <=)
end

function add_constraint_min_total_cumulated_unit_flow_from_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m, min_total_cumulated_unit_flow_from_node, >=)
end

function add_constraint_max_total_cumulated_unit_flow_to_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m, max_total_cumulated_unit_flow_to_node, <=)
end

function add_constraint_min_total_cumulated_unit_flow_to_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m, min_total_cumulated_unit_flow_to_node, >=)
end
