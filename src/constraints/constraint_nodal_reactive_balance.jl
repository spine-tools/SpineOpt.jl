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
As, [node](@ref)s represent electrical buses, they are the places where reactive
power balance is enforced. 
A reactive power balance is created for each [node](@ref) for all `node_stochastic_time_indices`
if the node belongs to an AC grid. The balance consists of unit flows and flows created 
by AC connections. In addition, the power lines themselves inject reactive power according
to their Pi-model.
    
```math
\begin{aligned}
& \sum_{conn} v^{connection\_flow\_reactive}_{(conn,n,to\_node,s,t)}
- \sum_{conn} v^{connection\_flow\_reactive}_{(conn,n,from\_node,s,t)} \\
& \sum_{conn} v^{line\_charging}_{(conn,n,to\_node,s,t)} + \sum_{conn} v^{line\_charging}_{(conn,n,from\_node,s,t)} \\
& +  \sum_{u} v^{unit\_flow\_reactive}_{(u,n,to\_node,s,t)} - \sum_{u} v^{unit\_flow\_reactive}_{(u,n,from\_node,s,t)} \\
& + v^{node\_voltage\_sq}_{(n,s,t)} \cdot p^{shunt\_susceptance}_{(n,s,t)}\\
& = p^{demand\_reactive}_{(n,s,t)} \\
& \forall n \in node:  \exists g \in grid : (n,g) \in node\_\_grid \wedge ^{}p^{physics\_type}_{(g)} = acflow\_physics \\
& \forall (s,t)
\end{aligned}

``` 
    
"""
function add_constraint_nodal_reactive_balance!(m::Model)
    _add_constraint!(m, :nodal_reactive_balance, constraint_nodal_reactive_balance_indices, 
        _build_constraint_nodal_reactive_balance)
end

function _build_constraint_nodal_reactive_balance(m, n, s, t1)
    @fetch unit_flow_reactive, connection_flow_reactive, node_voltage_squared = m.ext[:spineopt].variables
    @fetch line_charging_q = m.ext[:spineopt].expressions   
    @build_constraint(
        # Reactive power flows from connections (can be negative)
            + sum(
                connection_flow_reactive[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_reactive_flow_indices(
                    m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t1
                )
                if !_issubset(
                    connection__from_node(connection=conn, direction=direction(:from_node)), _internal_nodes(n)
                );
                init=0,
            )
            # Reactive power to connections (can be negative)
            - sum(
                connection_flow_reactive[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_reactive_flow_indices(
                    m; node=n, direction=direction(:from_node), stochastic_scenario=s, t=t1
                )
                if !_issubset(connection__to_node(connection=conn, direction=direction(:to_node)), _internal_nodes(n));
                init=0,
            )
            # Line charging reactive power in the Pi-model
            + sum(
               line_charging_q[conn, n1, d, s, t]
                for (conn, n1, d, s, t) in connection_reactive_flow_indices(
                    #m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t1
                    m; node=n, stochastic_scenario=s, t=t1
                ),
                init=0
            )
            # Flows from units (i.e. reactive power production)
            + sum(
                unit_flow_reactive[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_reactive_indices(
                    m;
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t1),
                    temporal_block=anything,
                );
                init=0,
            )
            # Flows to units  (i.e. reactive power absorption)
            - sum(
                unit_flow_reactive[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_reactive_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t1),
                    temporal_block=anything,
                );
                init=0,
            )
            == 
            # reactive power production of the shunt susceptance
            - node_voltage_squared[n, s, t1] * 
                shunt_susceptance(m; node=n, stochastic_scenario=s, t=t1)
            + demand_reactive(m; node=n, stochastic_scenario=s, t=t1)
            /
            (has_acflow(node=n) ? power_base(node=n) : 1 )

    )
end


function constraint_nodal_reactive_balance_indices(m)
    (
        (node=n, stochastic_scenario=s, t=t)
        for n in node()
        if has_acflow(node=n) == true
        for (n, s, t) in node_injection_indices(m; node=n)
    )
end