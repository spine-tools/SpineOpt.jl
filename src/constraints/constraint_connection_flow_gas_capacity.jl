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
    @fetch connection_flow,binary_connection_flow = m.ext[:variables]
    m.ext[:constraints][:connection_flow_gas_capacity] = Dict(
    (connection=conn, node1=n1, node2=n2, stochastic_scenario=s,t=t) => @constraint(
        m,
        sum(
        connection_flow[conn, n1, d, s, t]*duration(t)
        for (conn,n1,d,s,t) in connection_flow_indices(m;connection=conn, node=n1, stochastic_scenario=s, t=t_in_t(m;t_long=t),direction=direction(:to_node))
        )
        +
        sum(
        connection_flow[conn, n2, d, s, t]*duration(t)
        for (conn,n2,d,s,t) in connection_flow_indices(m;connection=conn, node=n2, stochastic_scenario=s, t=t_in_t(m;t_long=t),direction=direction(:from_node))
        ) /2
        <=
        + bigM(model=m.ext[:instance])
        *
        sum(
        binary_connection_flow[conn, n1, d, s, t]*duration(t)
        for (conn,n1,d,s,t) in connection_flow_indices(m;connection=conn, node=n1, stochastic_scenario=s, t=t_in_t(m;t_long=t),direction=direction(:to_node))
        )
        ) for (conn,n1,n2,s,t) in constraint_connection_flow_gas_capacity_indices(m)
        )
end

"""
    constraint_connection_flow_gas_capacity_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_flow_gas_capacity` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the highest resolution time slices are included.
"""
function constraint_connection_flow_gas_capacity_indices(
        m::Model;
        connection=anything,
        node1=anything,
        node2=anything,
        stochastic_path=anything,
        t=anything,
    )
    unique(
        (connection=conn, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (conn, n1, n2) in indices(fixed_pressure_constant_1; connection=connection, node1=node1, node2=node2)
        for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=[members(n1)...,members(n2)...]), t=t))
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_connection_flow_gas_capacity_indices(m, conn, n1, n2, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_connection_flow_gas_capacity_indices(m, conn, node1, node2, t)

Gather the indices of the relevant `connection_flow` variables.
"""
function _constraint_connection_flow_gas_capacity_indices(m, conn, node1, node2, t)
    Iterators.flatten((
        connection_flow_indices(m; connection=conn, node=node1, t=t),
        connection_flow_indices(m; connection=conn, node=node2, t=t)
    ))
end


# for (conn, n, d, s, t) in connection_flow_indices(m;node=node__commodity(commodity=commodity(:Gas)),direction=direction(:to_node))
# #TODO: replace this with connection_linepack_constant..pressuer thing; then you don't need has_state anymore
#     if has_state(node=n) == false
# #binary_connection_flow_indices
