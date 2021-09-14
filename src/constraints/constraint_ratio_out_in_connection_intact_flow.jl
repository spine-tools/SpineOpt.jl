#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    add_constraint_ratio_out_in_connection_intact_flow!(m, ratio_out_in, sense)

Ratio of `connection_intact_flow` variables.

Note that the `<sense>_ratio_<directions>_connection_intact_flow` parameter uses the stochastic dimensions of the second
<direction>!
"""
function add_constraint_ratio_out_in_connection_intact_flow!(m::Model)
    @fetch connection_intact_flow = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:ratio_out_in_connection_intact_flow] = Dict(
        (connection=conn, node1=ng_out, node2=ng_in, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + connection_intact_flow[conn, n_out, d, s, t_short] * duration(t_short)
                for (conn, n_out, d, s, t_short) in connection_intact_flow_indices(
                    m;
                    connection=conn,
                    node=ng_out,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            ==
            + expr_sum(
                + connection_intact_flow[conn, n_in, d, s, t_short] * duration(t_short)
                for (conn, n_in, d, s, t_short) in connection_intact_flow_indices(
                    m;
                    connection=conn,
                    node=ng_in,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
        ) for (conn, ng_in, ng_out, s, t) in constraint_ratio_out_in_connection_intact_flow_indices(m)
    )
end

function constraint_ratio_out_in_connection_intact_flow_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (connection=conn, node1=n_out, node2=n_in, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (n_in, n_out) in connection__node__node(connection=conn) for t in t_lowest_resolution(
            x.t for x in connection_flow_indices(
                m;
                connection=conn,
                node=Iterators.flatten((members(n_out), members(n_in))),
            )
        ) for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in _constraint_ratio_out_in_connection_intact_flow_indices(m, conn, n_in, n_out, t0, t)
            ),
        )
    )
end

"""
    constraint_ratio_out_in_connection_intact_flow_indices_filtered(m::Model; filtering_options...)

For investments with PTDF based flows, constraint the intact flow into a node to be equal to the flow out of the node.

Uses stochastic path indices due to potentially different stochastic structures between `connection_intact_flow` variables.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_out_in_connection_intact_flow_indices_filtered(
    m::Model;
    connection=connection(connection_monitored=true, has_ptdf=true),
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_out_in_connection_intact_flow_indices(m))
end

"""
    _constraint_ratio_out_in_connection_intact_flow_indices(connection, node_out, node_in, t0, t)

Gather the `connection_flow` variiable indices for `add_constraint_ratio_out_in_connection_flow!`.
"""

function _constraint_ratio_out_in_connection_intact_flow_indices(m, connection, node_in, node_out, t0, t)
    Iterators.flatten((
        connection_intact_flow_indices(
            m;
            connection=connection,
            node=node_out,
            direction=direction(:to_node),
            t=t_in_t(m; t_long=t),
        ),
        (connection=conn, node=n_in, direction=d, stochastic_scenario=s, t=t)
        for (conn, n_in, d, s, t1) in connection_intact_flow_indices(
            m;
            connection=connection,
            node=node_in,
            direction=direction(:from_node),
            t=t_in_t(m; t_long=t),
        )  # `from_node` `connection_flow`s
    ))
end
