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
    add_constraint_connection_intact_flow_ptdf!(m::Model)

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs.
"""
function add_constraint_connection_intact_flow_ptdf!(m::Model)
    @fetch connection_intact_flow, node_injection, connection_flow = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:connection_intact_flow_ptdf] = Dict(
        (connection=conn, node=n_to, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + get(connection_intact_flow, (conn, n_to, direction(:to_node), s, t), 0)
                - get(connection_intact_flow, (conn, n_to, direction(:from_node), s, t), 0)
                for s in s;
                init=0
            )
            ==
            + expr_sum(
                ptdf[(connection=conn, node=n, t=t)]
                * connection_availability_factor[(connection=conn, stochastic_scenario=s, t=t)]
                * node_injection[n, s, t]
                for n in ptdf_connection__node(connection=conn)
                if node_opf_type(node=n) != :node_opf_type_reference
                for (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s, t=t);                                  
                init=0
            )
            + expr_sum(
                ptdf[(connection=conn, node=n, t=t)]
                * connection_availability_factor[(connection=conn, stochastic_scenario=s, t=t)]
                * connection_flow[conn1, n1, d, s, t]                                
                for n in node(is_boundary_node=true)
                if n in ptdf_connection__node(connection=conn)
                && node_opf_type(node=n) != :node_opf_type_reference
                for (conn1, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:to_node), stochastic_scenario=s, t=t
                )
                if is_boundary_connection(connection=conn1);
                init=0
            )
            - expr_sum(
                ptdf[(connection=conn, node=n, t=t)]
                * connection_availability_factor[(connection=conn, stochastic_scenario=s, t=t)]
                * connection_flow[conn1, n1, d, s, t]                                
                for n in node(is_boundary_node=true)
                if n in ptdf_connection__node(connection=conn)
                && node_opf_type(node=n) != :node_opf_type_reference
                for (conn1, n1, d, s, t) in connection_flow_indices(
                    m; node=n, direction=direction(:from_node), stochastic_scenario=s, t=t
                )
                if is_boundary_connection(connection=conn1);
                init=0
            )
        )
        for (conn, n_to, s, t) in constraint_connection_intact_flow_ptdf_indices(m)
    )
end

# NOTE: always pick the second (last) node in `connection__from_node` as 'to' node

function constraint_connection_intact_flow_ptdf_indices(m::Model)
    (
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn; _compact=false), 1)
        for (n_to, t) in node_time_indices(m; node=n_to)
        for path in active_stochastic_paths(
            m,
            vcat(
                connection_intact_flow_indices(m; connection=conn, node=n_to, direction=d_to, t=t),
                node_stochastic_time_indices(m; node=ptdf_connection__node(connection=conn), t=t)
            )
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