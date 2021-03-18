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
    constraint_node_voltage_angle(m::Model)

Outer approximation of the non-linear terms.
"""
function constraint_node_voltage_angle(m::Model)
    @fetch node_voltage_angle = m.ext[:variables]
    @fetch connection_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:voltage_angle] = Dict()
    for conn in indices(line_susceptance)
        for (conn,n_from,c,d_from,t) in var_connection_flow_indices(connection=conn,direction=:from_node)
            for (conn,n_to,c,d_to,t)  in var_connection_flow_indices(connection=conn,commodity=c,direction=:to_node,t=t)
                if n_to != n_from
                    constr_dict[conn,n_from,t] = @constraint(
                        m,
                            connection_flow[conn,n_from,c,d_from,t]
                            -
                                connection_flow[conn,n_to,c,d_from,t]
                        ==
                        1/line_susceptance(connection=conn)
                        * 250
                        * (node_voltage_angle[n_from,t]
                            -
                                    node_voltage_angle[n_to,t])
                    )
                end
            end
        end
    end
end
