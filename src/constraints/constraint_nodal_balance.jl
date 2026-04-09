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
# TODO: as proposed in the wiki on groups: We should be able to support
# a) node_balance for node group and NO balance for underlying node
# b) node_balance for node group AND balance for underlying node

@doc raw"""
In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together.
An energy balance is created for each [node](@ref) for all `node_stochastic_time_indices`,
unless the [balance\_type](@ref) parameter of the node takes the value [balance\_type\_none](@ref balance_type_list)
or if the node in question is a member of a node group,
for which the [balance\_type](@ref) is [balance\_type\_group](@ref balance_type_list).
The parameter [nodal\_balance\_sense](@ref) defaults to equality,
but can be changed to allow overproduction ([nodal\_balance\_sense](@ref) [`>=`](@ref constraint_sense_list))
or underproduction ([nodal\_balance\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The energy balance is enforced by the following constraint:

```math
\begin{aligned}
& v^{node\_injection}_{(n,s,t)}
+ \sum_{
        conn
}
v^{connection\_flow}_{(conn,n,to\_node,s,t)}
- \sum_{
        conn
}
v^{connection\_flow}_{(conn,n,from\_node,s,t)} \\
& \begin{cases}
\ge & \text{if } p^{nodal\_balance\_sense} = ">=" \\
= & \text{if } p^{nodal\_balance\_sense} = "==" \\
\le & \text{if } p^{nodal\_balance\_sense} = "<=" \\
\end{cases} \\
& 0 \\
& \forall n \in node: p^{balance\_type}_{(n)} \ne balance\_type\_none \land \nexists ng \ni n : p^{balance\_type}_{(ng)} = balance\_type\_group \\
& \forall (s,t)
\end{aligned}
```

See also
[balance\_type](@ref) and [nodal\_balance\_sense](@ref).
"""
function add_constraint_nodal_balance!(m::Model)
    _add_constraint!(m, :nodal_balance, constraint_nodal_balance_indices, _build_constraint_nodal_balance)
end

function _build_constraint_nodal_balance(m, n, s, t)
    @fetch connection_flow, node_injection = m.ext[:spineopt].variables
    build_sense_constraint(
        # Net injection
        + node_injection[n, s, t]
        # Commodity flows from connections
        + sum(
            get(connection_flow, (conn, n1, d, s, t), 0)
            for n1 in members(n)
            for (conn, d) in connection__to_node(node=n1)
            if !_issubset(
                connection__from_node(connection=conn, direction=direction(:from_node)), _internal_nodes(n)
            );
            init=0,
        )
        # Commodity flows to connections
        - sum(
            get(connection_flow, (conn, n1, d, s, t), 0)
            for n1 in members(n)
            for (conn, d) in connection__from_node(node=n1)
            if !_issubset(connection__to_node(connection=conn, direction=direction(:to_node)), _internal_nodes(n));
            init=0,
        ),
        eval(nodal_balance_sense(node=n)),
        0,
    )
end

function constraint_nodal_balance_indices(m)
    (
        (node=n, stochastic_scenario=s, t=t)
        for n in node()
        if balance_type(node=n) !== :balance_type_none
        && !any(balance_type(node=ng) === :balance_type_group for ng in groups(n))
        for (n, s, t) in node_injection_indices(m; node=n)
    )
end

_internal_nodes(n::Object) = setdiff(members(n), n)

# NOTE: connections that don't have any nodes on the other side need the below to work
_issubset(x, y) = !isempty(x) && issubset(x, y)