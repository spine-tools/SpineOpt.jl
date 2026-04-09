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
To link the flow over a connection to the voltage angles of the adjacent nodes, the following constraint is imposed.
Note that this constraint is only generated if the parameter [connection\_reactance](@ref) is defined
for a [connection](@ref) object and if a [fix\_ratio\_out\_in\_connection\_flow](@ref) is defined
for a [connection\_\_node\_\_node](@ref) relationship involving that [connection](@ref).

```math
\begin{aligned}
& \sum_{n \in ng_{from}} v^{connection\_flow}_{(conn,n,from\_node,s,t)}
- \sum_{n \in ng_{to}} v^{connection\_flow}_{(conn,n,from\_node,s,t)}\\
& = \\
& \left(p^{connection\_reactance\_base}_{(conn,s,t)} \middle/ p^{connection\_reactance}_{(conn,s,t)}\right) \\
& \cdot \left(\sum_{n \in ng_{from}} v^{node\_voltage\_angle}_{(n,s,t)} - \sum_{n \in ng_{to}} v^{node\_voltage\_angle}_{(n,s,t)} \right)\\
& \forall (conn, ng_{to}, ng_{from}) \in indices(p^{fix\_ratio\_out\_in\_connection\_flow})\\
& \forall (s,t)
\end{aligned}
```

See also
[connection\_reactance](@ref),
[connection\_reactance\_base](@ref),
[fix\_ratio\_out\_in\_connection\_flow](@ref).
"""
function add_constraint_node_voltage_angle!(m::Model)
    _add_constraint!(
        m, :node_voltage_angle, constraint_node_voltage_angle_indices, _build_constraint_node_voltage_angle
    )
end

function _build_constraint_node_voltage_angle(m::Model, conn, n_to, n_from, s_path, t)
    @fetch node_voltage_angle, connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            connection_flow[conn, n_from, d_from, s, t]
            for (conn, n_from, d_from, s, t) in connection_flow_indices(
                m; connection=conn, node=n_from, direction=direction(:from_node), stochastic_scenario=s_path, t=t
            )
        )
        - sum(
            connection_flow[conn, n_to, d_from, s, t]
            for (conn, n_from, d_from, s, t) in connection_flow_indices(
                m; connection=conn, node=n_to, direction=direction(:from_node), stochastic_scenario=s_path, t=t
            )
        )
        ==
        sum(
            (
                + connection_reactance_base(m; connection=conn, stochastic_scenario=s, t=t)
                / connection_reactance(m; connection=conn, stochastic_scenario=s, t=t)
            )
            for s in s_path
        )
        / length(s_path)
        * (
            sum(
                node_voltage_angle[n_from, s, t]
                for (n_from, s, t) in node_voltage_angle_indices(m; node=n_from, stochastic_scenario=s_path, t=t)
            )
            - sum(
                node_voltage_angle[n_to, s, t]
                for (n_to, s, t) in node_voltage_angle_indices(m; node=n_to, stochastic_scenario=s_path, t=t)
            )
        )
    )
end

function constraint_node_voltage_angle_indices(m::Model)
    (
        (connection=conn, node1=n_to, node2=n_from, stochastic_path=path, t=t)
        for conn in indices(connection_reactance)
        for (conn, n_to, n_from) in indices(fix_ratio_out_in_connection_flow; connection=conn)
        if has_voltage_angle(node=n_from) && has_voltage_angle(node=n_to)
        for (t, path) in t_lowest_resolution_path(m, node_voltage_angle_indices(m; node=[n_to, n_from]))
    )
end

"""
    constraint_node_voltage_angle_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:node_voltage_angle` constraint.

Uses stochastic path indices of the `node_voltage_angle` and `connection_flow` variables.
Only the highest resolution time slices are included.(?)
"""
function constraint_node_voltage_angle_indices_filtered(
    m::Model;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_node_voltage_angle_indices(m))
end
