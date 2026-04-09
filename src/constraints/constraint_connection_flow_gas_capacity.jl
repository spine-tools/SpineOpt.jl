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
To enforce that the averge flow of a connection is only in one direction,
the flow in the opposite direction is forced to be `0` by the following equation.
For the connection flow in the direction of flow the parameter [big\_m](@ref) should be chosen large enough
not to become binding.

```math
\begin{aligned}
& 
\left.
\left(v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}\right)
\middle/2 
\right.
\\
& <= p^{big\_m} \cdot v^{binary\_gas\_connection\_flow}_{(conn, n_{dest}, to\_node, s, t)} \\
& \forall (conn, n_{orig}, n_{dest}) \in indices(p^{fixed\_pressure\_constant\_1}) \\
& \forall (s,t)
\end{aligned}
```

See also
[p^{fixed\_pressure\_constant\_1}](@ref),
[big\_m](@ref).
"""
function add_constraint_connection_flow_gas_capacity!(m::Model)
    _add_constraint!(
        m,
        :connection_flow_gas_capacity,
        constraint_connection_flow_gas_capacity_indices,
        _build_constraint_connection_flow_gas_capacity,
    )
end

function _build_constraint_connection_flow_gas_capacity(m::Model, conn, n_from, n_to, s_path, t)
    @fetch connection_flow, binary_gas_connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        (
            sum(
                connection_flow[conn, n_from, d, s, t] * duration(t)
                for (conn, n_from, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n_from,
                    stochastic_scenario=s_path,
                    t=t_in_t(m; t_long=t),
                    direction=direction(:from_node),
                )
            )
            + sum(
                connection_flow[conn, n_to, d, s, t] * duration(t)
                for (conn, n_to, d, s, t) in connection_flow_indices(
                    m; connection=conn,
                    node=n_to,
                    stochastic_scenario=s_path,
                    t=t_in_t(m; t_long=t),
                    direction=direction(:to_node),
                )
            )
        )
        / 2
        <=
        + big_m(model=m.ext[:spineopt].instance)
        * sum(
            binary_gas_connection_flow[conn, n_to, d, s, t] * duration(t)
            for (conn, n_to, d, s, t) in connection_flow_indices(
                m;
                connection=conn,
                node=n_to,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
                direction=direction(:to_node),
            )
        )
    )
end

function constraint_connection_flow_gas_capacity_indices(m::Model)
    (
        (connection=conn, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (conn, n1, n2) in indices(fixed_pressure_constant_1)
        for (t, path) in t_lowest_resolution_path(m, connection_flow_indices(m; connection=conn, node=[n1, n2]))
    )
end

"""
    constraint_connection_flow_gas_capacity_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_flow_gas_capacity` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the highest resolution time slices are included.
"""
function constraint_connection_flow_gas_capacity_indices_filtered(
    m::Model;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_flow_gas_capacity_indices(m))
end
