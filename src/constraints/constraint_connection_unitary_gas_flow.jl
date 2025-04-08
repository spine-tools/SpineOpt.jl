
1#############################################################################
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
The flow through a connection can only be in one direction at at time.
Whether a flow is active in a certain direction is indicated by the [binary\_gas\_connection\_flow](@ref) variable,
which takes a value of `1` if the direction of flow is positive.
To ensure that the [binary\_gas\_connection\_flow](@ref) in the opposite direction then takes the value `0`,
the following constraint is enforced:

```math
\begin{aligned}
& v^{binary\_gas\_connection\_flow}_{(conn, n_{orig}, to\_node, s, t)} \\
& = 1 - v^{binary\_gas\_connection\_flow}_{(conn, n_{dest}, to\_node, s, t)} \\
& \forall (conn, n_{orig}, n_{dest}) \in indices(p^{fixed\_pressure\_constant\_1}) \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connection_unitary_gas_flow!(m::Model)
    _add_constraint!(
        m,
        :connection_unitary_gas_flow,
        constraint_connection_flow_gas_capacity_indices,
        _build_constraint_connection_unitary_gas_flow,
    )
end

function _build_constraint_connection_unitary_gas_flow(m::Model, conn, n1, n2, s_path, t)
    @fetch binary_gas_connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        _avg(
            binary_gas_connection_flow[conn, n1, d, s, t]
            for (conn, n1, d, s, t) in connection_flow_indices(
                m;
                connection=conn,
                node=n1,
                stochastic_scenario=s_path,
                direction=direction(:to_node),
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        ==
        + 1
        - _avg(
            binary_gas_connection_flow[conn, n2, direction(:to_node), s, t]
            for (conn, n2, d, s, t) in connection_flow_indices(
                m;
                connection=conn,
                node=n2,
                stochastic_scenario=s_path,
                direction=direction(:to_node),
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
    )
end
