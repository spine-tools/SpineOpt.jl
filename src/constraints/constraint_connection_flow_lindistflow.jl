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
    function add_constraint_node_voltages_lindistflow()

    Add a constraint representing voltage drop in lindistflow formulation.
    This constraint ties together connection end point voltages, P and Q.

"""
function add_constraint_node_voltages_lindistflow!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) == :ac_opf_lindistflow
        _add_constraint!(m, :node_voltage_lindistflow, acflow_connection_nodepair_indices, 
            _build_constraint_node_voltage_lindistflow)
    end
end

function _build_constraint_node_voltage_lindistflow(m, conn, n1, n2, s, t) 
    @fetch connection_flow, connection_flow_reactive, node_voltage_squared = m.ext[:spineopt].variables
    @build_constraint(
        node_voltage_squared[n2, s, t]
        ==
        node_voltage_squared[n1, s, t]
        - 2 * connection_flow_reactive[conn, n1, direction(:from_node), s, t] 
        * connection_reactance(m, connection=conn, stochastic_scenario=s, t=t)
        - 2 * connection_flow[conn, n1, direction(:from_node), s, t]
        * connection_resistance(m, connection=conn, stochastic_scenario=s, t=t)
    )
end

"""
    function add_constraint_connection_flows_equal_lindistflow!()

    The function adds two constraints which set .
"""
function add_constraint_connection_flows_equal_lindistflow!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) == :ac_opf_lindistflow
        _add_constraint!(m, :connection_flow_real_equal, 
            acflow_connection_nodepair_indices, 
            _build_constraint_connection_flow_real_equal)
        _add_constraint!(m, :connection_flow_reactive_equal, 
            acflow_connection_nodepair_indices, 
            _build_constraint_connection_flow_reactive_equal)
    end
end

function _build_constraint_connection_flow_real_equal(m, conn, n1, n2, s, t)
    @fetch connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        connection_flow[conn, n2, direction(:to_node), s, t]
        ==
        connection_flow[conn, n1, direction(:from_node), s, t]
    )
end

function _build_constraint_connection_flow_reactive_equal(m, conn, n1, n2, s, t)
    @fetch connection_flow_reactive = m.ext[:spineopt].variables
    @build_constraint(
        connection_flow_reactive[conn, n2, direction(:to_node), s, t]
        ==
        connection_flow_reactive[conn, n1, direction(:from_node), s, t]
    )
end

"""
    function add_constraint_connection_maxpower_lindistflow!()

    The function sets the approximated maximum for connection current.
    
"""
function add_constraint_connection_maxpower_lindistflow!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) == :ac_opf_lindistflow
        _add_constraint!(m, :connection_maxpower_lindistflow, 
            constraint_connection_maxpower_lindistflow_indices, 
            _build_constraint_connection_maxpower_lindistflow)
    end
end

function _build_constraint_connection_maxpower_lindistflow(m, conn, n, d, s, t, alpha)
    @fetch connection_flow, connection_flow_reactive = m.ext[:spineopt].variables
    @build_constraint(
        connection_flow_reactive[conn, n, d, s, t]
        * sin(deg2rad(alpha))
        + connection_flow[conn, n, d, s, t] 
        * cos(deg2rad(alpha))
        <= (connection_current_max(m, connection=conn, stochastic_scenario=s, t=t))^2     
    )
end

"""
    function acflow_connection_nodepair_indices()

Produces a list of `NamedTuple`s corresponding all connections
and their source and destination nodes (connection, node1=source node, 
node2=destination node, s, t) where the relationship parameter 
connection_has_ac_flow(node1, node2, connection) has been set as true, 
as well as all time slices and stochastic scenarios relevant for the connection
flows to the destination node.
"""
function acflow_connection_nodepair_indices(
    m::Model;
    node1 = anything,
    node2 = anything,
    connection = anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing)
)
    ind = (
        (connection=conn, node1=n1, node2=n2, stochastic_scenario=s, t=t)
        for (conn, n1, n2) in indices(connection_has_ac_flow; connection=connection)
            if connection_has_ac_flow(node1=n1, node2=n2, connection=conn) == true
            for (conn_, n_, d, s, t) in 
                connection_flow_indices(m; connection=conn, node=n2, 
                    direction=direction(:to_node),
                    t=t)
    )
end

"""
    constraint_connection_maxpower_lindistflow_indices(m::Model)

    Produces the indices for AC connection flow in just one direction with
    and added alpha index.
"""
function constraint_connection_maxpower_lindistflow_indices(m::Model)
    num_angles_maxpower_lindistflow = 8
    ind = (
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t, alpha=alpha)
        for (conn, n, d, s, t) in
            constraint_connection_flow_acflow_indices(m, direction=direction(:to_node))
            for alpha in 0:360.0/num_angles_maxpower_lindistflow:359
    )
end