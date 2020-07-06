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

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

"""
    constraint_connection_flow_ptdf_indices()

Form the stochastic index set for the `:connection_flow_lodf` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`connection_flow` and `node_injection` variables?
"""
function constraint_connection_flow_ptdf_indices()
    unique(
        (connection=conn, node=n_to, stochastic_scenario=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (n_to, d_to) in Iterators.drop(connection__from_node(connection=conn), 1)
        for t in time_slice(temporal_block=node__temporal_block(node=n_to))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_connection_flow_ptdf_indices(conn, n_to, d_to, t))
        )
    )
end

"""
    _constraint_connection_flow_ptdf_indices(connection, node_to, direction_to, t)

Gather the indices of the `connection_flow` and the `node_injection` variables appearing in
`add_constraint_connection_flow_ptdf!`.
"""
function _constraint_connection_flow_ptdf_indices(connection, node_to, direction_to, t)
    Iterators.flatten(
        (
            connection_flow_indices(connection=connection, node=node_to, direction=direction_to, t=t),  # `n_to`
            (
                ind 
                for (conn, n_inj) in indices(ptdf; connection=connection)
                for ind in node_stochastic_time_indices(node=n_inj, t=t)
            )  # `n_inj`
        )
    )
end

"""
    add_constraint_connection_flow_ptdf!(m::Model)

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs.
"""
function add_constraint_connection_flow_ptdf!(m::Model)
    @fetch connection_flow, node_injection = m.ext[:variables]
    m.ext[:constraints][:connection_flow_ptdf] = Dict(
        (conn, n_to, stochastic_path, t) => @constraint(
            m,
            + expr_sum(
                + get(connection_flow, (conn, n_to, direction(:to_node), s, t), 0)
                - get(connection_flow, (conn, n_to, direction(:from_node), s, t), 0)
                for s in stochastic_path;
                init=0
            )
            ==
            + expr_sum(
                ptdf(connection=conn, node=n) * node_injection[n, s, t]
                for (conn, n) in indices(ptdf; connection=conn)
                for (n, s, t) in node_injection_indices(node=n, stochastic_scenario=stochastic_path, t=t)
                if !isapprox(ptdf(connection=conn, node=n), 0; atol=node_ptdf_threshold(node=n));
                init=0
            )
        )
        for (conn, n_to, stochastic_path, t) in constraint_connection_flow_ptdf_indices()
    )
end