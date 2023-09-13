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

"""
add_constraint_connection_flow_reactive!(m::Model)

Limit the maximum in/out `connection_flow_reactive` of a `connection` 
for all `connection_flow_voltage` indices based on the voltages which are defined 
for pairs of nodes in the voltage variables.


"""
function add_constraint_connection_flow_reactive!(m::Model)
    @fetch connection_flow_reactive, node_voltageproduct_cosine, 
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:connection_flow_reactive] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + connection_flow_reactive[conn, ng, d, s, t] 
                
           ==

           # if the node is an "in" node for the connection the summed value is multiplied by -1
           # because the direction is taken account in node balance equations
           - expr_sum(
                0.0 * (node_voltage_squared[n1, s, t] - node_voltageproduct_cosine[n1, n2, s, t] )
                - 5.0 * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in node_voltageproduct_indices(
                    m; node1_=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )

            # if the node is an "out" node for the connection
            + expr_sum(
                0.0 * (node_voltage_squared[n2, s, t] - node_voltageproduct_cosine[n1, n2, s, t])
                + 5.0 * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in node_voltageproduct_indices(
                    m; node2_=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )        
        )

        for (conn, ng, d, s, t) in constraint_connection_flow_voltage_indices(m)
    )
end

"""
add_constraint_connection_flow_real!(m::Model)

Limit the maximum in/out `connection_flow` of a `connection`, referring to the
real power transfer, for all `connection_flow_voltage` indices based on the voltages 
which are defined for pairs of nodes in the voltage variables.


"""
function add_constraint_connection_flow_real!(m::Model)
    @fetch connection_flow, node_voltageproduct_cosine,
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:connection_flow_real] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t) => @constraint(
            m,
            + connection_flow[conn, ng, d, s, t] 
                
           ==

           # if the node is an "in" node for the connection, the value is multiplied by -1
           # because the direction is taken account in node balance equations
           - expr_sum(
                5.0 * (node_voltageproduct_cosine[n1, n2, s, t] - node_voltage_squared[n1, s, t]) 
                - 0.0 * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in node_voltageproduct_indices(
                    m; node1_=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )

            # if the node is an "out" node for the connection
            + expr_sum(
                5.0 * (node_voltageproduct_cosine[n1, n2, s, t] - node_voltage_squared[n2, s, t]) 
                + 0.0 * node_voltageproduct_sine[n1, n2, s, t]
                for (n1, n2, s, t) in node_voltageproduct_indices(
                    m; node2_=ng, connection=conn, stochastic_scenario=s, t=t)
                ;
                init=0,
            )        
        )

        for (conn, ng, d, s, t) in constraint_connection_flow_voltage_indices(m)
    )
end

function constraint_connection_flow_voltage_indices(m::Model)
    
    connection_flow_indices(m, node=SpineOpt.node(has_voltage=true))
end



