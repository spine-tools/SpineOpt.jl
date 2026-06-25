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

"""
add_constraint_connection_flow_reactive!(m::Model)

Calculate the in/out `connection_flow_reactive` of a `connection` 
for all `connection_flow_voltage` indices based on the voltages which are defined 
for pairs of nodes in the voltage variables. Notice that the voltage variables 
in most cases have been defined for a pair of adjacent nodes (buses), either
representing the magnitude of their dot product or cross product.
"""
function add_constraint_connection_flow_reactive!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) ∈ [:ac_opf_conic, :ac_opf_linear]
        _add_constraint!(m, :connection_flow_reactive, constraint_connection_flow_acflow_indices, 
            _build_constraint_connection_flow_reactive)
    end
end

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


"""
add_constraint_connection_flow_real!(m::Model)

Calculate the in/out `connection_flow` of a `connection`, referring to the
real power transfer, for all `connection_flow_voltage` indices based on the voltages 
which are defined for pairs of nodes in the voltage variables.
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
        node=SpineOpt.node(has_voltage=true),
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t
    )
end




