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
    connection_reactive_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        stochastic_scenario=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `connection_flow_reactive` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_reactive_flow_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing))

    connection_flow_indices(m, 
        connection = unique(x.connection 
            for x in indices(connection_has_ac_flow; connection=connection)
                    #if connection_has_ac_flow(node1=x.node1, node2=x.node2, connection=x.connection) == true),
                    if connection_has_ac_flow(; x...) == true),
                    node=intersect(node, SpineOpt.node(has_voltage=true)),
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t,
        temporal_block=temporal_block )
end

"""
    add_variable_connection_flow_reactive!(m::Model)

Add `connection_flow_reactive` variables to model `m`, which represent reactive power flow
from connection to node or vice versa.
"""
function add_variable_connection_flow_reactive!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :connection_flow_reactive,
        connection_reactive_flow_indices
    )
end
