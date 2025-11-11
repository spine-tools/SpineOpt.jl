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

function connection_flow_lb(m; connection, node, direction, kwargs...)
    connection_flow_lower_limit(m; connection=connection, node=node, direction=direction, kwargs...) * (
        + number_of_connections(m; connection=connection, kwargs..., _default=1)
    )
end

function connection_flow_ub(m; connection, node, direction, kwargs...)
    (
        realize(
            connection_flow_capacity(m; connection=connection, node=node, direction=direction, _strict=false)
        ) === nothing
        || is_candidate(connection=connection)
        || members(node) != [node]
    ) && return NaN
    connection_flow_capacity(m; connection=connection, node=node, direction=direction, kwargs..., _default=NaN) * (
        + number_of_connections(m; connection=connection, kwargs..., _default=1)
        + something(candidate_connections(m; connection=connection, kwargs...), 0)
    )
end

function _fix_ratio_connection_flow(m, conn, n1, n2, s, t, fix_ratio, direct)
    if direct
        fix_ratio(m; connection=conn, node1=n1, node2=n2, stochastic_scenario=s, t=t)
    else
        _div_or_zero(1, fix_ratio(m; connection=conn, node1=n2, node2=n1, stochastic_scenario=s, t=t))
    end
end

function _has_simple_fix_ratio_out_in_connection_flow(conn, n1, n2, direct=true)
    n_to, n_from = direct ? (n1, n2) : (n2, n1)
    (
        _similar(n_to, n_from)
        && iszero(connection_flow_delay(connection=conn, node1=n_to, node2=n_from, _default=Hour(0)))
    )
end

"""
    add_variable_connection_flow!(m::Model)

Add `connection_flow` variables to model `m`.
"""
function add_variable_connection_flow!(m::Model)
    fix_ratio_d1_d2 = ((fix_ratio_out_in_connection_flow, direction(:to_node), direction(:from_node)),)
    replacement_expressions = OrderedDict(
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t) => [
            :connection_flow => Dict(
                (
                    connection=conn,
                    node=n_ref,
                    direction=d_ref,
                    stochastic_scenario=s,
                    t=t,
                ) => _fix_ratio_connection_flow(m, conn, n, n_ref, s, t, fix_ratio, direct)
            )
        ]
        for (conn, n_ref, d_ref, n, d, fix_ratio, direct) in _related_flows(fix_ratio_d1_d2)
        if _has_simple_fix_ratio_out_in_connection_flow(conn, n, n_ref, direct)
        for (_n, s, t) in node_stochastic_time_indices(m; node=n_ref)
    )
    add_variable!(
        m,
        :connection_flow,
        connection_flow_indices;
        lb=connection_flow_lb,
        ub=connection_flow_ub,
        fix_value=fix_connection_flow,
        initial_value=initial_connection_flow,
        non_anticipativity_time=connection_flow_non_anticipativity_time,
        non_anticipativity_margin=connection_flow_non_anticipativity_margin,
        required_history_period=maximum_parameter_value(connection_flow_delay),
        replacement_expressions=replacement_expressions,
    )
end
