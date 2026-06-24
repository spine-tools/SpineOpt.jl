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
add_constraint_connection_flow_current!(m::Model)

Limit the maximum squared current of a `connection` which has AC flow, for all 
    `acflow_nodepair_indices` indices. 


"""
function add_constraint_connection_flow_current!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) ∈ [:ac_opf_conic, :ac_opf_linear]
        _add_constraint!(m, :connection_flow_current, constraint_connection_flow_current_indices, 
            _build_constraint_connection_flow_current)
    end
end

function _build_constraint_connection_flow_current(m, conn, n1, n2, s, t)
    @fetch connection_flow_reactive, node_voltageproduct_cosine, 
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables
    
    @build_constraint(
        (connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t)
        * connection_susceptance(m, connection=conn, stochastic_scenario=s, t=t)
        + connection_conductance(m, connection=conn, stochastic_scenario=s, t=t)
        * connection_conductance(m, connection=conn, stochastic_scenario=s, t=t) ) 
        * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t] 
        - 2 * node_voltageproduct_cosine[n1, n2, s, t])
                
        <= connection_current_max(m, connection=conn, stochastic_scenario=s, t=t)
            * connection_current_max(m, connection=conn, stochastic_scenario=s, t=t)
    )
end

function constraint_connection_flow_current_indices(m)
    (
        (connection=conn, node1=n1, node2=n2, stochastic_scenario=s, t=t)
        for conn in indices(connection_current_max)
        for (n1, n2, s, t) in acflow_nodepair_indices(m; connection=conn)
    )
end

function add_constraint_connection_flow_current_old!(m::Model)
    @fetch connection_flow_reactive, node_voltageproduct_cosine, 
        node_voltageproduct_sine, node_voltage_squared = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:connection_flow_current] = Dict(
        (connection=conn, node1=n1, node2=n2, stochastic_scenario=s, t=t) => @constraint(
            m,
            + (connection_susceptance[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
             * connection_susceptance[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)] 
            + connection_conductance[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
            * connection_conductance[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)] ) 
                * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t] 
                - 2 * node_voltageproduct_cosine[n1, n2, s, t])
                
           <= connection_current_max[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
                * connection_current_max[(connection=conn, stochastic_scenario=s, analysis_time=t0, t=t)]
        )   
        for conn in indices(connection_current_max)
        for (n1, n2, s, t) in acflow_nodepair_indices(m; connection=conn)
    )
end

