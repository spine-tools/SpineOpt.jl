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
# TODO: as proposed in the wiki on groups: We should be able to support
# a) node_balance for node group and NO balance for underlying node
# b) node_balance for node group AND balance for underlying node

@doc raw"""
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.

#region description
``
In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together. An energy balance is created for each [node](@ref) for all `node_stochastic_time_indices`, unless the [balance\_type](@ref) parameter of the node takes the value [balance\_type\_none](@ref balance_type_list) or if the node in question is a member of a node group, for which the [balance\_type](@ref) is [balance\_type\_group](@ref balance_type_list). The parameter [nodal\_balance\_sense](@ref) defaults to equality, but can be changed to allow overproduction ([nodal\_balance\_sense](@ref) [`>=`](@ref constraint_sense_list)) or underproduction ([nodal\_balance\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The energy balance is enforced by the following constraint:
``
#endregion description

#region formulation
```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& + \sum_{\substack{(conn,n',d_{in},s,t) \in connection\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{connection\_flow}(conn,n',d_{in},s,t)\\
& - \sum_{\substack{(conn,n',d_{out},s,t) \in connection\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{connection\_flow}(conn,n',d_{out},s,t)\\
 & + v_{node\_slack\_pos}(n,s,t) \\
 & - v_{node\_slack\_neg}(n,s,t) \\
& \{>=,==,<=\} \\
& 0 \\
& \forall (n,s,t) \in node\_stochastic\_time\_indices: \\
& p_{balance\_type}(n) != balance\_type\_none \\
& \nexists ng \in groups(n) : balance\_type\_group \\
\end{aligned}
```
#endregion formulation
"""
function add_constraint_nodal_balance!(m::Model)
    @fetch connection_flow, node_injection = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:nodal_balance] = Dict(
        (node=n, stochastic_scenario=s, t=t) => sense_constraint(
            m,
            # Net injection
            + node_injection[n, s, t]
            # Commodity flows from connections
            + expr_sum(
                connection_flow[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t
                )
                if !_issubset(
                    connection__from_node(connection=conn, direction=direction(:from_node)), _internal_nodes(n)
                );
                init=0,
            )
            # Commodity flows to connections
            - expr_sum(
                connection_flow[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:from_node), stochastic_scenario=s, t=t
                )
                if !_issubset(connection__to_node(connection=conn, direction=direction(:to_node)), _internal_nodes(n));
                init=0,
            )
            ,
            eval(nodal_balance_sense(node=n)),
            0,
        )
        for n in node()
        if balance_type(node=n) !== :balance_type_none
        && !any(balance_type(node=ng) === :balance_type_group for ng in groups(n))
        for (n, s, t) in node_injection_indices(m; node=n)
    )
end

_internal_nodes(n::Object) = setdiff(members(n), n)

# NOTE: connections that don't have any nodes on the other side need the below to work
_issubset(x, y) = !isempty(x) && issubset(x, y)