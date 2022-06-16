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
    add_constraint_connection_flow_gas_capacity!(m::Model)

This constraint is needed to force uni-directional flow over gas connections.
"""
function add_constraint_connection_flow_gas_capacity!(m::Model)
    @fetch connection_flow, binary_gas_connection_flow = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:connection_flow_gas_capacity] = Dict(
        (connection=conn, node1=n_from, node2=n_to, stochastic_scenario=s, t=t) => @constraint(
            m,
            (
                sum(
                    connection_flow[conn, n_from, d, s, t] * duration(t)
                    for (conn, n_from, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_from,
                        stochastic_scenario=s,
                        t=t_in_t(m; t_long=t),
                        direction=direction(:from_node),
                    )
                ) + sum(
                    connection_flow[conn, n_to, d, s, t] * duration(t)
                    for (conn, n_to, d, s, t) in connection_flow_indices(
                        m;
                        connection=conn,
                        node=n_to,
                        stochastic_scenario=s,
                        t=t_in_t(m; t_long=t),
                        direction=direction(:to_node),
                    )
                )
            )
            / 2
            <=
            + big_m(model=m.ext[:spineopt].instance) * sum(
                binary_gas_connection_flow[conn, n_to, d, s, t] * duration(t)
                for (conn, n_to, d, s, t) in connection_flow_indices(
                    m;
                    connection=conn,
                    node=n_to,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                    direction=direction(:to_node),
                )
            )
        ) for (conn, n_from, n_to, s, t) in constraint_connection_flow_gas_capacity_indices(m)
    )
end

function constraint_connection_flow_gas_capacity_indices(m::Model)
    unique(
        (connection=conn, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (conn, n1, n2) in indices(fixed_pressure_constant_1) for t in t_lowest_resolution(
            time_slice(m; temporal_block=node__temporal_block(node=Iterators.flatten((members(n1), members(n2))))),
        ) for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in connection_flow_indices(m; connection=conn, node=[n1, n2], t=t)),
        )
    )
end

"""
    constraint_connection_flow_gas_capacity_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_flow_gas_capacity` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the highest resolution time slices are included.
"""
function constraint_connection_flow_gas_capacity_indices_filtered(
    m::Model;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_flow_gas_capacity_indices(m))
end
