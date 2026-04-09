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
    add_expression_capacity_margin!(m::Model)

Create an expression for `capacity_margin`. This represents the loat that must be met by conventional
    resources net of variable renewable production and storage. It is used in the `min_capacity_margin` constraint

```math 
\begin{aligned}
expr^{capacity\_margin}_{n,s,t} = \\
& + \sum_{u\in{U_{n\_to}}}(p^{unit\_capacity}_{u,s,t} \cdot p^{unit\_availability\_factor}_{u,s,t} \cdot v^{units\_available}_{u,s,t}) \\
& + \sum_{u\in{U_{storage_n}}}(v^{unit\_flow}_{u,n,to,s,t}) \\
& - \sum_{u\in{U_{storage_n}}}(v^{unit\_flow}_{u,n,from,s,t}) \\
& - p^{demand}_{n,s,t} \\
& - p^{fractional\_demand}_{n,s,t} \cdot p^{group\_demand}_{n_{group},s,t} \\
& \forall n \in node: p^{min\_capacity\_margin} \\
\end{aligned}
```
where ```math U_{storage_n} ``` is the set of all storage units connected to node n
and ```math U_{n\_to} ``` is the set of all non-storage units connected to node n

See also
[min\_capacity\_margin](@ref),
[min\_capacity\_margin\_penalty](@ref),
[unit\_\_from\_node](@ref),
[unit\_\_to\_node](@ref),
[demand](@ref),
[fractional\_demand](@ref),
[has\_state](@ref)

"""

function add_expression_capacity_margin!(m::Model)
    @fetch unit_flow, units_on = m.ext[:spineopt].variables
    m.ext[:spineopt].expressions[:capacity_margin] = Dict(
        (node=n, stochastic_path=s_path, t=t) => @expression(
            m,
            - maximum(_total_demand(m, n, s, t) for s in s_path)
            # Commodity flows to storage units
            - sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                )
                if is_storage_unit(u);
                init=0,
            )
            # Commodity flows from storage units
            + sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                )
                if is_storage_unit(u);
                init=0,
            )
            # Conventional and Renewable Capacity
            + sum(
                + sum(
                    unit_flow_capacity(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
                    for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=n, stochastic_scenario=s_path, t=t)
                )
                * (
                    + sum(
                        + _get_units_on(m, u, s, t_over)
                        for (u, s, t_over) in unit_stochastic_time_indices(
                            m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
                        );
                        init=0,
                    )
                )
                for (u, n, d) in indices(unit_capacity; node=n, direction=direction(:to_node))
                if !is_storage_unit(u)
            )
        )
        for (n, s_path, t) in expression_capacity_margin_indices(m)
    )
end

"""
    expression_capacity_margin_indices!(m::Model)

    Return the indices for the capacity_margin expression
"""

function expression_capacity_margin_indices(m::Model)
    (
        (node=n, stochastic_path=path, t=t)
        for n in indices(min_capacity_margin)
        for (n, t) in node_time_indices(m; node=n)
        for path in active_stochastic_paths(
            m,  
            Iterators.flatten(
                (
                    node_stochastic_time_indices(m; node=n, t=t),
                    unit_stochastic_time_indices(
                        m;
                        unit=Iterators.filter(
                            !is_storage_unit,
                            (u for (u, n, d) in indices(unit_capacity; node=n, direction=direction(:to_node))),
                        ),
                        t=t_overlaps_t(m; t=t),
                    ),
                )
            ),
        )
    )
end

"""
    is_storage_unit(u)

Whether the unit u is attached to a node with storage or not.
"""
function is_storage_unit(u)
    any(has_state(node=n) for n in unit__from_node(unit=u, direction=direction(:from_node)))
end
