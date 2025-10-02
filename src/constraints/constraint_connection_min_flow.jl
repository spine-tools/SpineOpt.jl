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
In a multi-commodity setting, there can be different commodities entering/leaving a certain connection.
These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The [connection\_capacity](@ref) and [connection\_min\_factor](@ref) 
should be specified for at least one [connection\_\_to\_node](@ref) or [connection\_\_from\_node](@ref) relationship,
in order to trigger a constraint on the minimum commodity flows to this location in each time step.
When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products).

```math
\begin{aligned}
& \sum_{n \in ng} v^{connection\_flow}_{(conn,n,d,s,t)} \\
& \geq \\
& p^{connection\_capacity}_{(conn,ng,d,s,t)} \cdot p^{connection\_min\_factor}_{(conn,s,t)} \cdot p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d,s,t)} \\
& \cdot \left( p^{number\_of\_connections}_{(conn,s,t)} + v^{connections\_invested\_available}_{(conn,s,t)} \right)\\
& \forall (conn,ng,d) \in indices(p^{connection\_capacity}) \\
& \forall (s,t)
\end{aligned}
```

See also
[connection\_capacity](@ref),
[connection\_min\_factor](@ref),
[connection\_conv\_cap\_to\_flow](@ref),
[number\_of\_connections](@ref),
[candidate\_connections](@ref)

!!! note
    For situations where the same [connection](@ref) handles flows to multiple [node](@ref)s
    with different temporal resolutions, the constraint is only generated for the lowest resolution,
    and only the average of the higher resolution flow is constrained.
    In other words, what gets constrained is the "average power" (e.g. MWh/h) rather than the "instantaneous power"
    (e.g. MW). If instantaneous power needs to be constrained as well, then [connection_capacity](@ref) needs to be
    specified separately for each [node](@ref) served by the [connection](@ref).

!!! note
    The conversion factor [connection\_conv\_cap\_to\_flow](@ref) has a default value of `1`,
    but can be adjusted in case the unit of measurement for the capacity is different to the connection flows
    unit of measurement.

"""
function add_constraint_connection_min_flow!(m::Model)
    _add_constraint!(
        m,
        :connection_min_flow,
        constraint_connection_min_flow_indices,
        _build_constraint_connection_min_flow,
    )
end

function _build_constraint_connection_min_flow(m, conn, ng, d, s_path, t)
    _build_constraint_connection_min_flow_simple(m, conn, ng, d, s_path, t)
end
function _build_constraint_connection_min_flow(m, conn, ng, ::Vector, s_path, t)
    _build_constraint_connection_min_flow_bidirectional(m, conn, ng, s_path, t)
end

function _build_constraint_connection_min_flow_simple(m, conn, ng, d, s_path, t)
    @build_constraint(
        + _term_connection_flow(m, conn, ng, d, s_path, t)
        >=
        + _term_total_number_of_connections(m, conn, ng, d, s_path, t)
        * _term_connection_flow_lower_limit(m, conn, ng, d, s_path, t)
    )
end

function _build_constraint_connection_min_flow_bidirectional(m, conn, ng, s_path, t)
    @build_constraint(
        sum(
            + _term_connection_flow(m, conn, ng, d, s_path, t)
            / _term_connection_flow_lower_limit(m, conn, ng, d, s_path, t)
            for d in direction()
        )
        >=
        + _term_total_number_of_connections(m, conn, ng, first(direction()), s_path, t)
    )
end

function _term_connection_flow_lower_limit(m, conn, ng, d, s_path, t)
    @fetch connection_flow = m.ext[:spineopt].variables
    (
        sum(
            connection_flow_lower_limit(m; connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)
            for s in s_path, t in t_in_t(m; t_long=t)
            if any(haskey(connection_flow, (conn, n, d, s, t)) for n in members(ng));
            init=0,
        )
        * duration(t)
    )
end

function constraint_connection_min_flow_indices(m::Model)    
    (
        (connection=conn, node=ng, direction=d, stochastic_path=path, t=t)
        for (conn, ng, d) in _connection_node_direction_for_min_flow(m)
        if members(ng) != [ng] || is_candidate(connection=conn)
        for (t, path) in t_lowest_resolution_path(
            m,
            connection_flow_indices(m; connection=conn, node=ng, direction=d),
            connections_invested_available_indices(m; connection=conn),
        )
    )
end


"""
    _connection_node_direction_for_min_flow(m)

An iterator over tuples (connection, node, direction) for which a connection_flow_lower_limit is specified.
If a capacity is specified for the same connection and node in the two directions and the 
connection_flow_lower_limit is not always zero, then the connection and node will be included in
only one tuple and the direction will be a `Vector` of the two directions.
In this case we can write a tight compact formulation.
"""
function _connection_node_direction_for_min_flow(m)
    froms = indices(connection_capacity, connection__from_node)
    tos = indices(connection_capacity, connection__to_node)
    iter = Iterators.flatten((froms, tos))
    if use_tight_compact_formulations(model=m.ext[:spineopt].instance)
        bidirectional = intersect(((x.connection, x.node) for x in froms), ((x.connection, x.node) for x in tos))
        filter!(x -> !_is_zero(_from_lower_limit(x)) && !_is_zero(_to_lower_limit(x)), bidirectional)
        Iterators.flatten(
            (
                (x for x in iter if !((x.connection, x.node) in bidirectional)),
                ((conn, n, direction()) for (conn, n) in bidirectional),
            )
        )
    else
        (x for x in iter if !_is_zero(connection_flow_lower_limit(; x...)))
    end
end

_from_lower_limit(x) = connection_flow_lower_limit(; zip((:connection, :node), x)..., direction=direction(:from_node))

_to_lower_limit(x) = connection_flow_lower_limit(; zip((:connection, :node), x)..., direction=direction(:to_node))
