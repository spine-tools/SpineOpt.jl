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
When calculating the in/out [connection\_flow\_reactive](@ref var_connection_flow_reactive) 
of a [connection](@ref) we must pay attention to the sign. For leaving node, the positive 
direction is that of the connection, i.e. withdrawal from the node. The equation in the SOCP
formulation (non-linear and linearized) is different
for the source and destination bus:

```math
\begin{aligned}
&v^{connection\_flow\_reactive}_{(conn,n,to\_node,s,t)} = \begin{cases}

\begin{aligned} 
& -p^{connection\_susceptance}_{(conn,s,t)} \cdot \left(  v^{node\_voltage\_sq}_{(n,s,t)} - v^{node\_voltage\_cos}_{(n,s,t)} \right) \\
& +p^{connection\_conductance}_{(conn,s,t)} * v^{node\_voltage\_sin}_{(n,n1,s,t)}\\
& \quad \text{if } (conn,n) \in connection\_\_from\_node
\end{aligned} \\


\begin{aligned} 
& p^{connection\_susceptance}_{(conn,s,t)} \cdot \left(  v^{node\_voltage\_sq}_{(n,s,t)} - v^{node\_voltage\_cos}_{(n1,n,s,t)} \right) \\
& +p^{connection\_conductance}_{(conn,s,t)} * v^{node\_voltage\_sin}_{(n1,n,s,t)}\\ 
& \quad \text{if } (conn,n) \in connection\_\_to\_node
\end{aligned}

\end{cases} \\

& \forall n \in node:  \exists g \in grid : (n,g) \in node\_\_grid \wedge ^{}p^{physics\_type}_{(g)} = acflow\_physics \\
& \forall (s,t)
\end{aligned}
```

"""
function add_constraint_connection_flow_reactive!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) ∈ [:ac_opf_conic, :ac_opf_linear]
        _add_constraint!(m, :connection_flow_reactive, constraint_connection_flow_acflow_indices, 
            _build_constraint_connection_flow_reactive)
    end
end

"""
Calculate the in/out `connection_flow_reactive` of a `connection` 
for all `connection_flow_voltage` indices based on the voltages which are defined 
for pairs of nodes in the voltage variables. Notice that the voltage variables 
in most cases have been defined for a pair of adjacent nodes (buses), either
representing the magnitude of their dot product or cross product.
"""
function  _build_constraint_connection_flow_reactive(m, conn, ng, d, s, t) 
     @fetch connection_flow_reactive, node_voltageproduct_cosine, 
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables

        @build_constraint(
             + connection_flow_reactive[conn, ng, d, s, t] 
                
           ==
           # if the node is an "in" node for the connection the summed value is multiplied by -1
           # because the direction is taken account in node balance equations
           - sum(
                connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t) * 
                (node_voltage_squared[n1, s, t] - node_voltageproduct_cosine[n1, n2, s, t] )
                - connection_conductance(m, connection=conn, stochastic_scenario=s, t=t)
                * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in acflow_nodepair_indices(
                    m; node1=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )

            # if the node is an "out" node for the connection
            + sum(
                connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t)
                * (node_voltage_squared[n2, s, t] - node_voltageproduct_cosine[n1, n2, s, t])
                + connection_conductance(m, connection=conn, stochastic_scenario=s, t=t)
                * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in acflow_nodepair_indices(
                    m; node2=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )     
        )
end


@doc raw"""
When calculating the in/out [connection\_flow](@ref var_connection_flow) 
of a [connection](@ref) we must pay attention to the sign. For leaving node, the positive 
direction is that of the connection, i.e. withdrawal from the node. The equation in the SOCP
formulation (non-linear and linearized) is different for the source and destination bus:

```math
\begin{aligned}
&v^{connection\_flow}_{(conn,n,to\_node,s,t)} = \begin{cases}

\begin{aligned} 
& -p^{connection\_conductance}_{(conn,s,t)} \cdot \left(  v^{node\_voltage\_sq}_{(n,s,t)} - v^{node\_voltage\_cos}_{(n,n1,s,t)} \right) \\
& +p^{connection\_susceptance}_{(conn,s,t)} * v^{node\_voltage\_sin}_{(n,n1,s,t)}\\
& \quad \text{if } (conn,n) \in connection\_\_from\_node
\end{aligned} \\


\begin{aligned} 
& p^{connection\_conductance}_{(conn,s,t)} \cdot \left(v^{node\_voltage\_cos}_{(n1,n,s,t)}  -v^{node\_voltage\_sq}_{(n,s,t)}  \right) \\
& +p^{connection\_susceptance}_{(conn,s,t)} * v^{node\_voltage\_sin}_{(n1,n,s,t)}\\ 
& \quad \text{if } (conn,n) \in connection\_\_to\_node
\end{aligned}

\end{cases} \\

& \forall n \in node:  \exists g \in grid : (n,g) \in node\_\_grid \wedge ^{}p^{physics\_type}_{(g)} = acflow\_physics \\
& \forall (s,t)
\end{aligned}
``` 

"""
function add_constraint_connection_flow_real!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) ∈ [:ac_opf_conic, :ac_opf_linear]
        _add_constraint!(m, :connection_flow_real, constraint_connection_flow_acflow_indices, 
            _build_constraint_connection_flow_real)
    end
end

function _build_constraint_connection_flow_real(m, conn, ng, d, s, t)
    @fetch connection_flow, node_voltageproduct_cosine,
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables

    @build_constraint(
        connection_flow[conn, ng, d, s, t] 
        ==
        # if the node is an "in" node for the connection, the value is multiplied by -1
        # because the direction is taken account in node balance equations
        - sum(
            connection_conductance(m, connection=conn, stochastic_scenario=s, t=t) * 
                (node_voltageproduct_cosine[n1, n2, s, t] - node_voltage_squared[n1, s, t]) 
            - connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t) 
            * node_voltageproduct_sine[n1, n2, s, t]
            for (n1, n2, s, t) in acflow_nodepair_indices(
                m; node1=ng, connection=conn, stochastic_scenario=s, t=t)
            ;
            init=0,
        )

        # if the node is an "out" node for the connection
        + sum(
            connection_conductance(m, connection=conn, stochastic_scenario=s, t=t) * 
                (node_voltageproduct_cosine[n1, n2, s, t] - node_voltage_squared[n2, s, t]) 
            + connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t) 
            * node_voltageproduct_sine[n1, n2, s, t]
            for (n1, n2, s, t) in acflow_nodepair_indices(
                m; node2=ng, connection=conn, stochastic_scenario=s, t=t)
            ;
            init=0,
        )        
    )
end


"""
    constraint_connection_flow_acflow_indices(m::Model)

    The connection flow indices for which AC flow constraint for connection flows 
    are set. The connection must have AC flow set, and the node in question must 
    have voltage. This assumes that the connection only has two end nodes.
"""
function constraint_connection_flow_acflow_indices(m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything)
    connection_flow_indices(m,
        connection = intersect(connection, x.connection 
                for x in indices(connection_has_ac_flow) 
                      if connection_has_ac_flow(; x...) == true),
        node=SpineOpt.node(has_acflow=true),
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t
    )
end




