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
    node_voltageproduct_indices(    )

A list of `NamedTuple`s corresponding to indices for the `node_voltageproduct_cosine` and `node_voltageproduct_sine` variables.

"""
function node_voltageproduct_indices(
    m::Model;
    node1 = anything,
    node2 = anything,
    connection = anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing)
)

    ind = unique(
        (node1=n1, node2=n2, stochastic_scenario=s, t=t)
        for (conn, n1, n2) in indices(connection_has_ac_flow; connection=connection)
            if connection_has_ac_flow(node1=n1, node2=n2, connection=conn) == true
            for (conn_, n_, d, s, t) in connection_flow_indices(m; connection=conn, node=n2, direction=direction(:to_node))
           
        #for (conn, n1, d) in connection__from_node()
        #    for (n2, d) in connection__to_node(connection=conn)
        #        if fix_ratio_out_in_connection_flow[(connection=conn, node1=n2, node2=n1)] == 1
        #            for (conn_, n_, d, s, t) in connection_flow_indices(m; 
        #                connection=conn, node=n2, direction=direction(:to_node))
    )
    
     
    # filter the index set with respect to other indices
    f(ind) = _index_in(ind; node1=node1, node2=node2, stochastic_scenario=stochastic_scenario, t=t)
    filter(f, ind)
                    
end

"""
    node_voltage_squared_indices(    )

A list of `NamedTuple`s corresponding to indices of the `node_voltage_squared` variable.

Any filtering options can be specified for `node`, `s`, and `t`.
"""
function node_voltage_squared_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    inds = NamedTuple{(:node, :stochastic_scenario, :t),Tuple{Object,Object,TimeSlice}}[
        (node=n, stochastic_scenario=s, t=t) for (n, s, t) in node_stochastic_time_indices(
            m;
            node=intersect(node, SpineOpt.node(has_voltage=true)),
            stochastic_scenario=stochastic_scenario,
            t=t,
            temporal_block=temporal_block,
        )
    ]
    unique!(inds)
end

"""
add_variable_node_voltageproduct_cosine!(m::Model)

Add `node_voltageproduct_cosine` variables to model `m`. 

This variable has been defined for connections and node pairs within the connection 
which have been marked as `connection_has_ac_flow`, i.e. AC flow is simulated for that connection 
and specific pair of nodes. The variable is defined as the dot product of the voltage 
phasors, in other words cos(theta)*V(node1)*V(node2), where theta is the angle between
the voltage phasors and V is the voltage magnitude. node1 corresponds to the "from node" and 
node2 the "to node".
"""
function add_variable_node_voltageproduct_cosine!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :node_voltageproduct_cosine,
        node_voltageproduct_indices
    )
end

"""
add_variable_node_voltageproduct_sine!(m::Model)

Add `node_voltageproduct_sine` variables to model `m`.

This variable has been defined for connections and node pairs within the connection 
which have been marked as `connection_has_ac_flow`, i.e. AC flow is simulated for that connection 
and specific pair of nodes. The variable is defined as the dot product of the voltage 
phasors, in other words sin(theta)*V(node1)*V(node2), where theta is the angle between
the voltage phasors and V is the voltage magnitude. node1 corresponds to the "from node" and 
node2 the "to node". theta is positive when the voltage phasor of node2 is ahead of that of
node1.

"""
function add_variable_node_voltageproduct_sine!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :node_voltageproduct_sine,
        node_voltageproduct_indices
    )
end

"""
add_variable_node_squared!(m::Model)

Add `add_variable_node_squared` variables to model `m`.

The variable is defined as the square of voltage magnitude in the node.
"""
function add_variable_node_voltage_squared!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :node_voltage_squared,
        node_voltage_squared_indices;
        lb=min_voltage,
        ub=constant(1.0)
    )
end
