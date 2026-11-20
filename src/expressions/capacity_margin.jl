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

Create an expression for `capacity_margin`. This represents the load that must be met by conventional
resources net of variable renewable production and storage. It is used in the `min_capacity_margin` constraint.

The expression is indexed by node, stochastic *path* and time slice. A path ``\hat{s}`` is a sequence of
consecutive stochastic scenarios. Each entity (node, unit, connection, investment) contributes the variables
and parameter values of the scenario in ``\hat{s}`` that is active for it at `t`, even when these entities
have different stochastic structures.

```math
\begin{aligned}
expr^{capacity\_margin}_{n,\hat{s},t} = \\
& - \max_{s \in \hat{s}} \left( p^{demand}_{n,s,t}
    + p^{fractional\_demand}_{n,s,t} \cdot p^{group\_demand}_{n_{group},s,t} \right) \\
& - \sum_{u,\, n' \in n,\, s \in \hat{s}} v^{unit\_flow}_{u,n',from,s,t} \\
& + \sum_{u \in U_{flow},\, n' \in n,\, s \in \hat{s}} v^{unit\_flow}_{u,n',to,s,t} \\
& + \sum_{c,\, n' \in n,\, s \in \hat{s}} v^{connection\_flow}_{c,n',to,s,t} \\
& - \sum_{c,\, n' \in n,\, s \in \hat{s}} v^{connection\_flow}_{c,n',from,s,t} \\
& + \sum_{u \notin U_{flow},\, n' \in n} p^{unit\_flow\_capacity}_{u,n',s,t} \cdot \left(
    \sum_{s' \in \hat{s}} v^{units\_invested\_available}_{u,s',t}
    + p^{number\_of\_units}_{u,s,t} - p^{units\_unavailable}_{u,s,t} \right) \\
& \forall n \in node: p^{min\_capacity\_margin} \\
\end{aligned}
```
where ``U_{flow}`` is the set of units with `use_flow_capacity_contribution`, whose net `unit_flow` counts
towards the margin instead of their capacity, and ``n' \in n`` ranges over the member nodes of `n`.
Connection flows are only counted if the connection's other end is outside of `n`.

See also
[min\_capacity\_margin](@ref),
[min\_capacity\_margin\_penalty](@ref),
[use\_flow\_capacity\_contribution](@ref),
[unit\_\_from\_node](@ref),
[unit\_\_to\_node](@ref),
[demand](@ref),
[fractional\_demand](@ref),
[has\_state](@ref)
"""
function add_expression_capacity_margin!(m::Model)
    @fetch unit_flow, units_invested_available, connection_flow = m.ext[:spineopt].variables
    m.ext[:spineopt].expressions[:capacity_margin] = Dict(
        (node=n, stochastic_path=s_path, t=t) => @expression(
            m,
            # Peak demand over the scenarios in the path
            - maximum(_total_demand(m, n, s, t) for s in s_path)
            # Commodity flows from the node into units
            # NOTE: unlike the next term, this one is not restricted to flow units
            - sum(
                unit_flow[u, n1, d, s, t_short]
                for (u, n1, d, s, t_short) in unit_flow_indices(
                    m;
                    node=members(n),
                    direction=direction(:from_node),
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                );
                init=0,
            )
            # Commodity flows from flow units to the node
            + sum(
                unit_flow[u, n1, d, s, t_short]
                for (u, n1, d, s, t_short) in unit_flow_indices(
                    m;
                    node=members(n),
                    direction=direction(:to_node),
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                )
                if is_flow_unit(u);
                init=0,
            )
            # Commodity flows from connections into the node (group), from outside of it
            + sum(
                connection_flow[c, n2, d2, s, t_short]
                for n1 in members(n)
                for (conn, d) in connection__to_node(node=n1)
                if !_issubset(
                    connection__from_node(connection=conn, direction=direction(:from_node)), _internal_nodes(n)
                )
                for (c, n2, d2, s, t_short) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n1,
                    direction=d,
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                );
                init=0,
            )
            # Commodity flows from the node (group) to connections, to outside of it
            - sum(
                connection_flow[c, n2, d2, s, t_short]
                for n1 in members(n)
                for (conn, d) in connection__from_node(node=n1)
                if !_issubset(
                    connection__to_node(connection=conn, direction=direction(:to_node)), _internal_nodes(n)
                )
                for (c, n2, d2, s, t_short) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n1,
                    direction=d,
                    stochastic_scenario=s_path,
                    t=t,
                    temporal_block=anything,
                );
                init=0,
            )
            # Conventional and renewable capacity (non flow units), including investments.
            # The capacity is taken at the scenario of the unit's flow in the path;
            # investments are looked up over the whole path, since they can live in an earlier scenario.
            + sum(
                sum(
                    unit_flow_capacity(m; unit=u, node=n1, direction=d, stochastic_scenario=s, t=t_flow)
                    * (
                        sum(
                            units_invested_available[u, s_inv, t_inv]
                            for (_u, s_inv, t_inv) in units_invested_available_indices(
                                m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t_flow)
                            );
                            init=0,
                        )
                        + number_of_units(m; unit=u, stochastic_scenario=s, t=t_flow, _default=_default_nb_of_units(u))
                        - units_unavailable(m; unit=u, stochastic_scenario=s, t=t_flow)
                    )
                    for (_u, _n, _d, s, t_flow) in unit_flow_indices(
                        m; unit=u, node=n1, direction=d, stochastic_scenario=s_path, t=t
                    )
                )
                for (u, n1, d) in indices(unit_capacity; node=members(n), direction=direction(:to_node))
                if !is_flow_unit(u);
                init=0,
            )
        )
        for (n, s_path, t) in expression_capacity_margin_indices(m)
    )
end

"""
    expression_capacity_margin_indices(m::Model)

Return the indices for the capacity_margin expression: node, stochastic path and time slice.
The paths are built from the scenarios of everything that contributes to the expression,
so that each contributing entity has an active scenario in every path.
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
                    node_stochastic_time_indices(m; node=members(n), t=t),
                    unit_stochastic_time_indices(
                        m;
                        unit=[
                            u
                            for (u, _n, _d) in indices(
                                unit_capacity; node=members(n), direction=direction(:to_node)
                            )
                            if !is_flow_unit(u)
                        ],
                        t=t_overlaps_t(m; t=t),
                    ),
                    units_invested_available_indices(
                        m;
                        unit=[
                            u
                            for (u, _n, _d) in indices(
                                unit_capacity; node=members(n), direction=direction(:to_node)
                            )
                            if !is_flow_unit(u)
                        ],
                        t=t_overlaps_t(m; t=t),
                    ),
                )
            ),
        )
    )
end

"""
    is_flow_unit(u)

Whether the unit `u` contributes to the capacity margin with its `unit_flow`, rather than with its capacity.
"""
function is_flow_unit(u)
    use_flow_capacity_contribution(unit=u, _default=false)
end
