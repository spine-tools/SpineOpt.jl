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
    add_constraint_connection_intact_flow_ptdf!(m::Model)

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs.
"""
function add_constraint_connection_intact_flow_ptdf!(m::Model)
    @fetch connection_intact_flow, node_injection = m.ext[:variables]
    m.ext[:constraints][:connection_intact_flow_ptdf] = Dict(
        (connection=conn, node=n_to, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + get(connection_intact_flow, (conn, n_to, direction(:to_node), s, t), 0)
                - get(connection_intact_flow, (conn, n_to, direction(:from_node), s, t), 0) for s in s;
                init=0,
            )
            ==
            + expr_sum(
                ptdf(connection=conn, node=n) * node_injection[n, s, t]
                for (conn, n) in indices(ptdf; connection=conn)
                for (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s, t=t)
                    if !isapprox(ptdf(connection=conn, node=n), 0; atol=node_ptdf_threshold(node=n));
                init=0,
            )
        ) for (conn, n_to, s, t) in constraint_connection_intact_flow_ptdf_indices(m)
    )
end

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

function constraint_connection_intact_flow_ptdf_indices(m::Model)
    unique(
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn; _compact=false), 1)
        for (n_to, t) in node_time_indices(m; node=n_to) for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in _constraint_connection_intact_flow_ptdf_indices(m, conn, n_to, d_to, t)
            ),
        )
    )
end

"""
    constraint_connection_intact_flow_ptdf_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_intact_flow_lodf` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`connection_intact_flow` and `node_injection` variables? Keyword arguments can be used for filtering the resulting Array.
"""
function constraint_connection_intact_flow_ptdf_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_intact_flow_ptdf_indices(m))
end

"""
    _constraint_connection_intact_flow_ptdf_indices(connection, node_to, direction_to, t)

Gather the indices of the `connection_intact_flow` and the `node_injection` variables appearing in
`add_constraint_connection_intact_flow_ptdf!`.
"""
function _constraint_connection_intact_flow_ptdf_indices(m, connection, node_to, direction_to, t)
    Iterators.flatten((
        connection_intact_flow_indices(m; connection=connection, node=node_to, direction=direction_to, t=t),
        (
            ind
            for (conn, n_inj) in indices(ptdf; connection=connection)
            for ind in node_stochastic_time_indices(m; node=n_inj, t=t)
        ),  # `n_inj`
    ))
end
