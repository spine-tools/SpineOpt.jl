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

When a [connection](@ref) linking to a [node](@ref) is bidirectionally bounded (the [connection\_capacity](@ref)s 
of both directions have positive values), a compact linear constraint is generated to ensure that the simutanous flows 
in both directions do not exceed their own capacity nor does their sum exceed the capacity in each direction.

```math
\begin{aligned}
& \frac{
    \sum_{n \in ng} v^{connection\_flow}_{(conn,n,d,s,t)}
    }{
        p^{connection\_capacity}_{(conn,ng,d,s,t)} \cdot 
        p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d,s,t)}
    } \\
& + \frac{
    \sum_{n \in ng} v^{connection\_flow}_{(conn,n,d\_reverse,s,t)}
    }{
        p^{connection\_capacity}_{(conn,ng,d\_reverse,s,t)} \cdot 
        p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d\_reverse,s,t)}
    } \\
& \leq p^{connection\_availability\_factor}_{(conn,s,t)} \\
& \cdot \begin{cases}       
   v^{connections\_invested\_available}_{(conn,s,t)} 
   & \text{if } p^{candidate\_connections}_{(conn,s,t)} \geq 1 \\
   1 & \text{otherwise} \\
\end{cases} \\
& \forall  (conn, ng, d, d\_reverse) \in indices(p^{connection\_capacity}): \\ 
& \quad \text{(1) } \exist d\_reverse \\
& \qquad \ \land p^{connection\_capacity}_{(conn,ng,d,s,t)} \cdot 
          p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d,s,t)} > 0 \\
& \qquad \ \land p^{connection\_capacity}_{(conn,ng,d\_reverse,s,t)} \cdot 
          p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d\_reverse,s,t)} > 0 \\
& \forall (s,t)
\end{aligned}
```

For the rest cases, a constraint is generated for each bounded direction of the [connection](@ref) 
to ensure that the flow does not exceed the capacity.

```math
\begin{aligned}
& \sum_{n \in ng} v^{connection\_flow}_{(conn,n,\_d,s,t)} \\
& \leq p^{connection\_availability\_factor}_{(conn,s,t)} \\
& \cdot p^{connection\_capacity}_{(conn,ng,\_d,s,t)} \cdot 
     p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,\_d,s,t)} \\
& \cdot \begin{cases}       
   v^{connections\_invested\_available}_{(conn,s,t)} 
   & \text{if } p^{candidate\_connections}_{(conn,s,t)} \geq 1 \\
   1 & \text{otherwise} \\
\end{cases} \\
& \forall \_d \in \{d, d\_reverse\}: \exist \_d \\
& \forall (conn, ng, d, d\_reverse) \in indices(p^{connection\_capacity}): \\
& \quad \neg \text{(1)} \\
& \forall (s,t)
\end{aligned}
```

```math
\begin{aligned}
& \text{where:} \\
& \text{(i) } \exist x \Leftrightarrow x \neq nothing \\
& \text{(ii) } (conn, ng, d, d\_reverse) \in indices(p^{connection\_capacity}) \\
& \quad \Rightarrow \exist d \Rightarrow \exist p^{connection\_capacity}_{(conn,ng,d,s,t)} \\
& \text{(iii) } \exist d\_reverse \in (conn, ng, d, d\_reverse) \\
& \quad \Rightarrow \exist p^{connection\_capacity}_{(conn,ng,d\_reverse,s,t)} \\
\end{aligned}
```

See also
[connection\_capacity](@ref),
[connection\_availability\_factor](@ref),
[connection\_conv\_cap\_to\_flow](@ref),
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
        (
            !isnothing(d_reverse)
            #TODO: would using realize() significantly threaten the performance?
            && realize(connection_capacity[
                (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
            ]) * realize(connection_conv_cap_to_flow[
                (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t),
            ]) > 0
            && realize(connection_capacity[
                (connection=conn, node=ng, direction=d_reverse, stochastic_scenario=s, analysis_time=t0, t=t)
            ]) * realize(connection_conv_cap_to_flow[
                (connection=conn, node=ng, direction=d_reverse, stochastic_scenario=s, analysis_time=t0, t=t),
            ]) > 0 ? 
            (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
                m,
                + sum(
                    connection_flow[conn, n, d, s, t] * duration(t)
                    for (conn, n, d, s, t) in connection_flow_indices(
                        m; connection=conn, direction=d, node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                    );
                    init=0,
                ) / (
                    connection_capacity[
                        (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
                    ] * connection_conv_cap_to_flow[
                        (connection=conn, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t),
                    ]
                )
                + sum(
                    connection_flow[conn, n, d_reverse, s, t] * duration(t)
                    for (conn, n, d_reverse, s, t) in connection_flow_indices(
                        m; connection=conn, direction=d_reverse, node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                    );
                    init=0,
                ) / (
                    connection_capacity[
                        (connection=conn, node=ng, direction=d_reverse, stochastic_scenario=s, analysis_time=t0, t=t)
                    ] * connection_conv_cap_to_flow[
                        (connection=conn, node=ng, direction=d_reverse, stochastic_scenario=s, analysis_time=t0, t=t),
                    ]
                )
                #TODO: operator `/` may cause numerical unstability if the denumerator is too close to zero
                <=
                + connection_availability_factor[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
                * (
                    !isnothing(candidate_connections(connection=conn)) ? sum(
                        connections_invested_available[conn, s, t1]
                        for (conn, s, t1) in connections_invested_available_indices(
                            m; connection=conn, stochastic_scenario=s, t=t_in_t(m; t_short=t)
                        );
                        init=0,
                    ) : 1
                )
                * duration(t)
            ) : 
            (connection=conn, node=ng, direction=_d, stochastic_path=s, t=t) => @constraint(
                m, 
                + sum(
                    connection_flow[conn, n, _d, s, t] * duration(t)
                    for (conn, n, _d, s, t) in connection_flow_indices(
                        m; connection=conn, direction=_d, node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                    );
                    init=0,
                )
                <=
                + connection_capacity[
                    (connection=conn, node=ng, direction=_d, stochastic_scenario=s, analysis_time=t0, t=t)
                ]
                * connection_availability_factor[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
                * connection_conv_cap_to_flow[
                    (connection=conn, node=ng, direction=_d, stochastic_scenario=s, analysis_time=t0, t=t),
                ]
                * (
                    !isnothing(candidate_connections(connection=conn)) ? sum(
                        connections_invested_available[conn, s, t1]
                        for (conn, s, t1) in connections_invested_available_indices(
                            m; connection=conn, stochastic_scenario=s, t=t_in_t(m; t_short=t)
                        );
                        init=0,
                    ) : 1
                )
                * duration(t)
            )
        ) 
        for (conn, ng, d, d_reverse, s, t) in constraint_connection_flow_capacity_indices(
            m; incl_reverse_direction=true
        )
        for _d in (d, d_reverse) if !isnothing(_d)
    )
end

function constraint_connection_flow_capacity_indices(m::Model; incl_reverse_direction=false)    
    incl_reverse_direction ? 
    # A tuple of unique indices containing both directions
    unique!(
        ind -> Set(values(ind)), 
        # Array for the unique!() function, converted into a Tuple afterwards
        [
            (
                # Potential threat to performance
                (connection=conn, node=ng, direction=_d_reverse(d)) in indices(connection_capacity) ?
                (connection=conn, node=ng, direction=d, direction_reverse=_d_reverse(d), stochastic_path=path, t=t) : 
                (connection=conn, node=ng, direction=d, direction_reverse=nothing, stochastic_path=path, t=t)
            ) 
            for (conn, ng, d) in indices(connection_capacity)
            for (t, path) in t_lowest_resolution_path(
                m,
                connection_flow_indices(m; connection=conn, node=ng, direction=d),
                connections_invested_available_indices(m; connection=conn),
            )
        ]
    ) |> Tuple :
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
    f(ind) = _index_in(
        ind; connection=connection, node=node, direction=direction, stochastic_path=stochastic_path, t=t
    )
    filter(f, constraint_connection_flow_capacity_indices(m))
end
