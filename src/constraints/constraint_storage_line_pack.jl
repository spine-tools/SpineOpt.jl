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
    add_constraint_storage_line_pack!(m::Model)

Constraint for line storage dependent on line pack.
"""
function add_constraint_storage_line_pack!(m::Model)
    @fetch node_state, node_pressure = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:storage_line_pack] = Dict(
        (connection=conn, node1=stor, node2=ng, stochastic_path=s, t=t) => @constraint(
            m,
            sum(
                node_state[stor, s, t] * duration(t)
                for (stor, s, t) in node_state_indices(m; node=stor, stochastic_scenario=s, t=t_in_t(m; t_long=t))
            )
            ==
            connection_linepack_constant(connection=conn, node1=stor, node2=ng)
            * 0.5
            * sum( #summing up the partial pressure of each component for both sides
                node_pressure[ng, s, t] * duration(t)
                for (ng, s, t) in node_pressure_indices(m; node=ng, stochastic_scenario=s, t=t_in_t(m; t_long=t))
            )
        )
        for (conn, stor, ng, s, t) in constraint_storage_line_pack_indices(m)
    )
end

function constraint_storage_line_pack_indices(m::Model)
    unique(
        (connection=conn, node1=n_stor, node2=ng, stochastic_path=path, t=t)
        for (conn, n_stor, ng) in indices(connection_linepack_constant)
        for (t, path) in t_lowest_resolution_path(
            vcat(node_state_indices(m; node=n_stor), node_pressure_indices(m; node=ng))
        )
    )
end

"""
    constraint_storage_line_pack_indices_filtered(m::Model)
"""
function constraint_storage_line_pack_indices_filtered(
    m::Model; connection=anything,
    node_stor=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(
        ind,
    ) = _index_in(
        ind;
        connection=connection,
        node_stor=node_stor,
        node1=node1,
        node2=node2,
        stochastic_path=stochastic_path,
        t=t,
    )
    filter(f, constraint_storage_line_pack_indices(m))
end