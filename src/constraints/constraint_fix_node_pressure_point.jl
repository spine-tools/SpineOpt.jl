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
The Weymouth equation relates the average flows through a connection to the difference between the adjacent
squared node pressures.

```math
\begin{aligned}
& \left(
    \left(
        v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)}
        + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}
    \right)
    - \left(
        v^{connection\_flow}_{(conn, n_{dest},from\_node,s,t)}
        + v^{connection\_flow}_{(conn, n_{orig},to\_node,s,t)}
    \right)
\right)
\\
& \cdot \left\|
    \left(
        v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)}
        + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}
    \right)
    - \left(
        v^{connection\_flow}_{(conn, n_{dest},from\_node,s,t)}
        + v^{connection\_flow}_{(conn, n_{orig},to\_node,s,t)}
    \right)
\right\|
\\
& = 4 \cdot K_{(conn)} \cdot \left(
    \left(v^{node\_pressure}_{(n_{orig},s,t)}\right)^2 - \left(v^{node\_pressure}_{(n_{dest},s,t)}\right)^2
\right) \\
\end{aligned}
```
where ``K`` corresponds to the natural gas flow constant.

The above can be rewritten as
```math
\begin{aligned}
& \left(
\left(v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}\right)
- \left(v^{connection\_flow}_{(conn, n_{dest},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{orig},to\_node,s,t)}\right)
\right)\\
& = 2 \cdot \sqrt{
    K_{(conn)}
    \cdot \left(
        \left(v^{node\_pressure}_{(n_{orig},s,t)}\right)^2 - \left(v^{node\_pressure}_{(n_{dest},s,t)}\right)^2
    \right)
} \\
& \text{if } \left(
    v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}
\right) > 0
\end{aligned}
```
and
```math
\begin{aligned}
& \left(
    \left(
        v^{connection\_flow}_{(conn, n_{dest},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{orig},to\_node,s,t)}
    \right)
    - \left(
        v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}
    \right)
\right) \\
& = 2 \cdot \sqrt{
    K_{(conn)} \cdot \left(
        \left(v^{node\_pressure}_{(n_{dest},s,t)}\right)^2 - \left(v^{node\_pressure}_{(n_{orig},s,t)}\right)^2
    \right)
} \\
& \text{if } \left(
    v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}
\right) < 0
\end{aligned}
```

The cone described by the Weymouth equation can be outer approximated by a number of tangent planes,
using a set of fixed pressure points, as illustrated in
[Schwele - Integration of Electricity, Natural Gas and Heat Systems With Market-based Coordination]
(https://orbit.dtu.dk/en/publications/integration-of-electricity-natural-gas-and-heat-systems-with-mark).
The big M method is used to replace the sign function.

The linearized version of the Weymouth equation implemented in SpineOpt is given as follows:

```math
\begin{aligned}
& 
\left.
\left(v^{connection\_flow}_{(conn, n_{orig},from\_node,s,t)} + v^{connection\_flow}_{(conn, n_{dest},to\_node,s,t)}\right)
\middle/2 
\right.
\\
& \leq p^{fixed\_pressure\_constant\_1}_{(conn,n_{orig},n_{dest},j,s,t)} \cdot v^{node\_pressure}_{(n_{orig},s,t)} \\
& - p^{fixed\_pressure\_constant\_0}_{(conn,n_{orig},n_{dest},j,s,t)} \cdot v^{node\_pressure}_{(n_{dest},s,t)} \\
& + p^{big\_m} \cdot \left(1 - v^{binary\_gas\_connection\_flow}_{(conn, n_{dest}, to\_node, s, t)}\right) \\
& \forall (conn, n_{orig}, n_{dest}) \in indices(p^{fixed\_pressure\_constant\_1}) \\
& \forall j \in \left\{1, \ldots, \left\| p^{fixed\_pressure\_constant\_1}_{(conn, n_{orig}, n_{dest})} \right\| \right\}:
p^{fixed\_pressure\_constant\_1}_{(conn, n_{orig}, n_{dest}, j)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```

The parameters [fixed\_pressure\_constant\_1](@ref) and [fixed\_pressure\_constant\_0](@ref) should be defined.
For each considered fixed pressure point, they can be calculated as follows:
```math
\begin{aligned}
  & p^{fixed\_pressure\_constant\_1}_{(conn,n_{orig},n_{dest},j)} =
  \left. K_{(conn)} \cdot p^{fixed\_pressure}_{(n_{orig},j)} \middle/ \sqrt{
    \left(p^{fixed\_pressure}_{(n_{orig},j)}\right)^2 - \left(p^{fixed\_pressure}_{(n_{dest},j)}\right)^2
  }\right. \\
  & p^{fixed\_pressure\_constant\_0}_{(conn,n_{orig},n_{dest},j)} =
  \left. K_{(conn)} \cdot p^{fixed\_pressure}_{(n_{dest},j)} \middle/ \sqrt{
    \left(p^{fixed\_pressure}_{(n_{orig},j)}\right)^2 - \left(p^{fixed\_pressure}_{(n_{dest},j)}\right)^2
  }\right. \\
\end{aligned}
```
where ``p^{fixed\_pressure}_{(n,j)}`` is the fix pressure for node ``n`` and point ``j``.

The [big\_m](@ref) parameter combined with the variable [binary\_gas\_connection\_flow](@ref)
together with the equations [on unitary gas flow](@ref constraint_connection_unitary_gas_flow)
and on the [maximum gas flow](@ref constraint_connection_flow_gas_capacity) ensure that
the bound on the average flow through the fixed pressure points becomes active,
if the flow is in a positive direction for the observed set of connection, node1 and node2.

See also
[fixed\_pressure\_constant\_1](@ref),
[fixed\_pressure\_constant\_0](@ref),
[big\_m](@ref).
"""
function add_constraint_fix_node_pressure_point!(m::Model)
    _add_constraint!(
        m,
        :fix_node_pressure_point,
        constraint_fix_node_pressure_point_indices,
        _build_constraint_fix_node_pressure_point,
    )
end

function _build_constraint_fix_node_pressure_point(m::Model, conn, n_orig, n_dest, s_path, t, j)
    @fetch node_pressure, connection_flow, binary_gas_connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        (
            sum(
                connection_flow[conn, n_orig, d, s, t]
                for (conn, n_orig, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n_orig,
                    stochastic_scenario=s_path,
                    direction=direction(:from_node),
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            + sum(
                connection_flow[conn, n_dest, d, s, t]
                for (conn, n_dest, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n_dest,
                    stochastic_scenario=s_path,
                    direction=direction(:to_node),
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
        )
        / 2
        <=
        + sum(
            + node_pressure[n_orig, s, t]
            * fixed_pressure_constant_1(m; connection=conn, node1=n_orig, node2=n_dest, i=j, stochastic_scenario=s, t=t)
            for (n_orig, s, t) in node_pressure_indices(
                m; node=n_orig, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        - sum(
            + node_pressure[n_dest, s, t]
            * fixed_pressure_constant_0(m; connection=conn, node1=n_orig, node2=n_dest, i=j, stochastic_scenario=s, t=t)
            for (n_dest, s, t) in node_pressure_indices(
                m; node=n_dest, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )            
        + big_m(model=m.ext[:spineopt].instance)
        * sum(
            1 - binary_gas_connection_flow[conn, n_dest, direction(:to_node), s, t]
            for (conn, n_dest, d, s, t) in connection_flow_indices(
                m;
                connection=conn,
                node=n_dest,
                stochastic_scenario=s_path,
                direction=direction(:to_node),
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
    )
end

function constraint_fix_node_pressure_point_indices(m::Model)
    (
        (connection=conn, node1=n_orig, node2=n_dest, stochastic_path=s_path, t=t, i=j)
        for (conn, n_orig, n_dest, s_path, t) in constraint_connection_flow_gas_capacity_indices(m)
        for j in 1:length(fixed_pressure_constant_1(connection=conn, node1=n_orig, node2=n_dest))
        if fixed_pressure_constant_1(connection=conn, node1=n_orig, node2=n_dest, i=j) != 0
    )
end
