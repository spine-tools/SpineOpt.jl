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
    binary_gas_connection_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `binary_gas_connection_flow_indices` variable.
The keyword arguments act as filters for each dimension.
"""
function binary_gas_connection_flow_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=direction(:to_node),
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node = members(node)
    (
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
        for (conn, n, d, s, t) in connection_flow_indices(
            m;
            connection=intersect(connection, SpineOpt.connection(has_binary_gas_flow=true)),
            node=intersect(node, SpineOpt.node(has_state=false)),
            stochastic_scenario=stochastic_scenario,
            direction=direction,
            t=t,
            temporal_block=temporal_block,
        )
    )
end

set_bin(x) = true

"""
    add_variable_connection_flow!(m::Model)

Add `connection_flow` variables to model `m`.
"""
function add_variable_binary_gas_connection_flow!(m::Model)
    add_variable!(
        m,
        :binary_gas_connection_flow,
        binary_gas_connection_flow_indices;
        bin=set_bin,
        fix_value=fix_binary_gas_connection_flow,
        initial_value=initial_binary_gas_connection_flow,
    )
end
