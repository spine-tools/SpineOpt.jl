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
        for (conn, n, d) in connection__node__direction(
            connection=connection, node=node, direction=direction, _compact=false
        )
        for (n, s, t) in node_stochastic_time_indices(
            m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

function _is_delayless_lossless(conn, n_to, n_from)
    (
        fix_ratio_out_in_connection_flow(connection=conn, node1=n_to, node2=n_from) == 1
        && iszero(connection_flow_delay(connection=conn, node1=n_to, node2=n_from))
        && node__temporal_block(node=n_to) == node__temporal_block(node=n_from)
    )
end

"""
    add_variable_connection_flow!(m::Model)

Add `connection_flow` variables to model `m`.
"""
function add_variable_connection_flow!(m::Model)
    ind_map = Dict(
        (connection=conn, node=n_to, direction=direction(:to_node), stochastic_scenario=s, t=t) => (
            connection=conn, node=n_from, direction=direction(:from_node), stochastic_scenario=s, t=t
        )
        for (conn, n_to, n_from) in indices(fix_ratio_out_in_connection_flow)
        if _is_delayless_lossless(conn, n_to, n_from)
        for (_n, s, t) in node_stochastic_time_indices(m; node=n_to)
    )
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
        ind_map=ind_map,
    )
end
