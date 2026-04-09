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
The power transfer distribution factors are a property of the network reactances.
``p^{ptdf}_{(c, n)}`` represents the fraction of an injection at [node](@ref) ``n`` that will flow
on [connection](@ref) ``c``.
The flow on [connection](@ref) ``c`` is then the sum over all nodes of ``p^{ptdf}_{(c, n)}`` multiplied by the
net injection at that node.
[connection\_intact\_flow](@ref) represents the flow on each line of the network with all candidate connections
with PTDF-based flow present in the network.

```math
\begin{aligned}
& v^{connection\_intact\_flow}_{(c, n_{to}, to\_node, s, t)}
- v^{connection\_intact\_flow}_{(c, n_{to}, from\_node, s, t)} \\
& = \sum_{n_{inj}} p^{ptdf}_{(c, n_{inj}, t)} \cdot v^{node\_injection}_{(n_{inj}, s, t)}
\cdot \left[p^{node\_opf\_type}_{(n_{inj})} \neq node\_opf\_type\_reference \right]
\\
& \forall c \in connection : p^{is\_monitored}_{(c)} \\
& \forall (s,t)
\end{aligned}
```
where
```math
[p] \vcentcolon = \begin{cases}
1 & \text{if } p \text{ is true;}\\
0 & \text{otherwise.}
\end{cases}
```

"""
function add_constraint_connection_intact_flow_ptdf!(m::Model)
    _add_constraint!(
        m,
        :connection_intact_flow_ptdf,
        constraint_connection_intact_flow_ptdf_indices,
        _build_constraint_connection_intact_flow_ptdf,
    )
end

function _build_constraint_connection_intact_flow_ptdf(m::Model, conn, n_to, s_path, t)
    @fetch connection_intact_flow, node_injection, connection_flow = m.ext[:spineopt].variables
    if !use_connection_intact_flow(model=m.ext[:spineopt].instance)
        connection_intact_flow = connection_flow
    end
    @build_constraint(
        + sum(
            + get(connection_intact_flow, (conn, n_to, direction(:to_node), s, t), 0)
            - get(connection_intact_flow, (conn, n_to, direction(:from_node), s, t), 0)
            for s in s_path;
            init=0
        )
        ==
        + sum(
            ptdf(m; connection=conn, node=n, t=t)
            * connection_availability_factor(m; connection=conn, stochastic_scenario=s, t=t)
            * node_injection[n, s, t]
            for n in ptdf_connection__node(connection=conn)
            if node_opf_type(node=n) != :node_opf_type_reference
            for (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s_path, t=t);
            init=0
        )
        + sum(
            ptdf(m; connection=conn, node=n, t=t)
            * connection_availability_factor(m; connection=conn, stochastic_scenario=s, t=t)
            * connection_flow[conn1, n1, d, s, t]
            for n in node(is_boundary_node=true)
            if n in ptdf_connection__node(connection=conn)
            && node_opf_type(node=n) != :node_opf_type_reference
            for (conn1, n1, d, s, t) in connection_flow_indices(
                m; node=n, direction=direction(:to_node), stochastic_scenario=s_path, t=t
            )
            if is_boundary_connection(connection=conn1);
            init=0
        )
        - sum(
            ptdf(m; connection=conn, node=n, t=t)
            * connection_availability_factor(m; connection=conn, stochastic_scenario=s, t=t)
            * connection_flow[conn1, n1, d, s, t]
            for n in node(is_boundary_node=true)
            if n in ptdf_connection__node(connection=conn)
            && node_opf_type(node=n) != :node_opf_type_reference
            for (conn1, n1, d, s, t) in connection_flow_indices(
                m; node=n, direction=direction(:from_node), stochastic_scenario=s_path, t=t
            )
            if is_boundary_connection(connection=conn1);
            init=0
        )
    )
end

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

function constraint_connection_intact_flow_ptdf_indices(m::Model)
    (
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn; _compact=false), 1)
        for (n_to, t) in node_time_indices(m; node=n_to)
        if _check_ptdf_duration(m, t, conn)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    connection_intact_flow_indices(m; connection=conn, node=n_to, direction=d_to, t=t),
                    node_stochastic_time_indices(m; node=ptdf_connection__node(connection=conn), t=t),
                )
            )
        )
    )
end

"""
    constraint_connection_intact_flow_ptdf_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_intact_flow_lodf` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`connection_intact_flow` and `node_injection` variables? Keyword arguments can be used for filtering the resulting Array.
"""
function constraint_connection_intact_flow_ptdf_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_intact_flow_ptdf_indices(m))
end