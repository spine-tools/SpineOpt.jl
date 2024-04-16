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
    connection_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `connection_flow` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_flow_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node = members(node)
    (
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
        for (conn, n, d, tb) in connection__node__direction__temporal_block(
            connection=connection, node=node, direction=direction, temporal_block=temporal_block, _compact=false
        )
        for (n, s, t) in node_stochastic_time_indices(
            m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
    )
end

"""
    add_variable_connection_flow!(m::Model)

Add `connection_flow` variables to model `m`.
"""
function add_variable_connection_flow!(m::Model)
    add_variable!(
        m,
        :connection_flow,
        connection_flow_indices;
        lb=constant(0),
        fix_value=fix_connection_flow,
        initial_value=initial_connection_flow,
        non_anticipativity_time=connection_flow_non_anticipativity_time,
        non_anticipativity_margin=connection_flow_non_anticipativity_margin,
        required_history_period=maximum_parameter_value(connection_flow_delay),
    )
end
