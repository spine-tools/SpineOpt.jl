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
In a multi-commodity setting, there can be different commodities entering/leaving a certain connection.
These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The [connection\_capacity](@ref) should be specified
for at least one [connection\_\_to\_node](@ref) or [connection\_\_from\_node](@ref) relationship,
in order to trigger a constraint on the maximum commodity flows to this location in each time step.
When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products).

```math
\begin{aligned}
& \sum_{n \in ng} v^{connection\_flow}_{(conn,n,d,s,t)} \\
& <= \\
& p^{connection\_capacity}_{(conn,ng,d,s,t)} \cdot p^{connection\_availability\_factor}_{(conn,s,t)} \cdot p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d,s,t)} \\
& \cdot \left( p^{number\_of\_connections}_{(conn,s,t)} + v^{connections\_invested\_available}_{(conn,s,t)} \right)\\
& \forall (conn,ng,d) \in indices(p^{connection\_capacity}) \\
& \forall (s,t)
\end{aligned}
```

See also
[connection\_capacity](@ref),
[connection\_availability\_factor](@ref),
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
function add_constraint_connection_flow_capacity!(m::Model)
    @fetch connection_flow, connections_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:connection_flow_capacity] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s_path, t=t) => @constraint(
            m,
            + sum(
                get(connection_flow, (conn, n, d, s, t), 0) * duration(t)
                for n in members(ng)
                for s in s_path
                for t in t_in_t(m; t_long=t);
                init=0,
            )
            <=
            + sum(
                + connection_capacity(
                    m; connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t
                )
                * connection_availability_factor(m; connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)
                * connection_conv_cap_to_flow(
                    m; connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t
                )
                * (
                    + sum(
                        get(connections_invested_available, (conn, s, t1), 0)
                        for s in s_path
                        for t1 in t_in_t(m; t_short=t);
                        init=0,
                    )
                    + number_of_connections(
                        m;
                        connection=conn,
                        stochastic_scenario=s,
                        analysis_time=t0,
                        t=t,
                        _default=_default_number_of_connections(conn),
                    )
                )
                for s in s_path
                for t in t_in_t(m; t_long=t)
                if any(haskey(connection_flow, (conn, n, d, s, t)) for n in members(ng));
                init=0,
            )
            * duration(t)
        )
        for (conn, ng, d, s_path, t) in constraint_connection_flow_capacity_indices(m)
    )
end

_default_number_of_connections(conn) = is_candidate(connection=conn) ? 0 : 1

function constraint_connection_flow_capacity_indices(m::Model)
    (
        (connection=conn, node=ng, direction=d, stochastic_path=path, t=t)
        for (conn, ng, d) in indices(connection_capacity)
        for (t, path) in t_lowest_resolution_path(
            m,
            connection_flow_indices(m; connection=conn, node=ng, direction=d),
            connections_invested_available_indices(m; connection=conn),
        )
    )
end

"""
    constraint_connection_flow_capacity_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_flow_capacity` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting
"""
function constraint_connection_flow_capacity_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_flow_capacity_indices(m))
end
