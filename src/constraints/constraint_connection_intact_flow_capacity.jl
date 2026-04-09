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
Similarly to [this](@ref constraint_connection_flow_capacity), limits [connection\_intact\_flow](@ref)
according to [connection\_capacity](@ref)

```math
\begin{aligned}
& \sum_{
n \in ng
} v^{connection\_intact\_flow}_{(conn,n,d,s,t)} \\
& \leq \\
& p^{connection\_capacity}_{(conn,ng,d,s,t)} \cdot p^{connection\_availability\_factor}_{(conn,s,t)}
\cdot p^{connection\_conv\_cap\_to\_flow}_{(conn,ng,d,s,t)} \\
& \cdot \left( p^{number\_of\_connections}_{(conn,s,t)} + p^{candidate\_connections}_{(conn,s,t)} \right)
\\
& \forall (conn,ng,d) \in indices(p^{connection\_capacity}) \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connection_intact_flow_capacity!(m::Model)
    use_connection_intact_flow(model=m.ext[:spineopt].instance) || return
    _add_constraint!(
        m,
        :connection_intact_flow_capacity,
        constraint_connection_intact_flow_capacity_indices,
        _build_constraint_connection_intact_flow_capacity,
    )
end

function _build_constraint_connection_intact_flow_capacity(m::Model, conn, ng, d, s_path, t)
    @fetch connection_intact_flow = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            connection_intact_flow[conn, n, d, s, t] * duration(t)
            for (conn, n, d, s, t) in connection_intact_flow_indices(
                m; connection=conn, direction=d, node=ng, stochastic_scenario=s_path, t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        <=
        sum(
            + connection_capacity(m; connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)
            * connection_availability_factor(m; connection=conn, stochastic_scenario=s, t=t)
            * connection_conv_cap_to_flow(m; connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)
            * (
                + candidate_connections(m; connection=conn, stochastic_scenario=s, t=t, _default=0)
                + number_of_connections(
                    m; connection=conn, stochastic_scenario=s, t=t, _default=_default_nb_of_conns(conn)
                )
            )
            for (conn, n, d, s, t) in connection_intact_flow_indices(
                m; connection=conn, direction=d, node=ng, stochastic_scenario=s_path, t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        * duration(t)
    )
end

function constraint_connection_intact_flow_capacity_indices(m::Model)
    (
        (connection=c, node=ng, direction=d, stochastic_path=path, t=t)
        for (c, ng, d) in indices(connection_capacity; connection=connection(has_ptdf=true))
        for (t, path) in t_lowest_resolution_path(
            m, connection_intact_flow_indices(m; connection=c, node=ng, direction=d)
        )
    )
end

"""
    constraint_connection_intact_flow_capacity_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_intact_flow_capacity` constraint.

Uses stochastic path indices of the `connection_intact_flow` variables. Only the lowest resolution time slices are
included, as the `:connection_intact_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting
"""
function constraint_connection_intact_flow_capacity_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_intact_flow_capacity_indices(m))
end
