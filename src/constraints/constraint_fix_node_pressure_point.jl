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
    constraint_fix_node_pressure_point(m::Model)

Outer approximation of the non-linear terms.
"""
function constraint_fix_node_pressure_point(m::Model)
    @fetch node_pressure,connection_flow,binary_connection_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:fix_node_pressure_point] = Dict()
    for (conn, n_orig, n_dest) in indices(K1)
        for (conn,n_orig,c,d_from,t) in connection_flow_indices(connection=conn,node=n_orig,direction=:from_node)
            for j = 1:length(K1(connection=conn,node1=n_orig,node2=n_dest))
                if K1(connection=conn,node1=n_orig,node2=n_dest,i=j) != 0
                    constr_dict[conn, n_orig, n_dest, j, t] = @constraint(
                        m,
                        (connection_flow[conn,n_orig,c,d_from,t] + connection_flow[conn,n_dest,c,Object("to_node"),t])/2 ##### TO DO from node, to node???? for all segments??????
                        <=
                        + K1(connection=conn,node1=n_orig,node2=n_dest,i=j) * node_pressure[n_orig,t] - K0(connection=conn,node1=n_orig,node2=n_dest,i=j)* node_pressure[n_dest,t]
                        + bigM(model=:instance)* (1-binary_connection_flow[conn, n_dest, Object("to_node"), t])
                    )
                end
            end
        end
    end
end
