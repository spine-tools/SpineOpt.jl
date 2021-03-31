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
    @fetch node_state, node_pressure = m.ext[:variables]
    constr_dict = m.ext[:constraints][:storage_line_pack] = Dict()
    # for (n,conn,d) in connection__node__direction()
    for conn in indices(connection_linepack_constant)
        for (n_orig,n_dest) in connection__node__node(connection=conn)
            for (conn,n,d,s,t) in connection_flow_indices(m,connection=conn)
                if is_linepack_storage(node=n)
                    constr_dict[conn, n, t] = @constraint(
                        m,
                        node_state[n,s,t] ##TODO: how to identify gas_storage nodes?
                        ==
                        connection_linepack_constant(connection=conn)*0.5*(node_pressure[n_orig,s,t]+node_pressure[n_dest,s,t])
                        )
                end
            end ###TODO: revise!
            end
    end
    # end
end

"""
    constraint_storage_line_pack_indices(m::Model)

"""
    function constraint_storage_line_pack_indices(
        m::Model;
        connection=anything,
        node1=anything,
        node2=anything,
        stochastic_path=anything,
        t=anything,
    )
        unique(
            (connection=c, node1=node_origin, node2=node_destination, stochastic_path=path, t=t)
            for c_ in indices(connection_linepack_constant)
            for (c, node_origin, node_destination) in indices(unit_capacity) if u in unit && ng in node && d in direction
            for t in t_lowest_resolution(time_slice(m; temporal_block=node__temporal_block(node=members(ng)), t=t))
            for
            path in active_stochastic_paths(unique(
                ind.stochastic_scenario for ind in _constraint_unit_flow_capacity_indices(m, u, ng, d, t)
            )) if path == stochastic_path || path in stochastic_path
        )
    end
