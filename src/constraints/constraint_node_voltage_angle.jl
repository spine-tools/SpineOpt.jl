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
function add_constraint_node_voltage_angle!(m::Model)
    @fetch node_voltage_angle = m.ext[:variables]
    @fetch connection_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:voltage_angle] = Dict()
    for conn in indices(connection_reactance)
        for (conn,n_from,d_from,s,t) in connection_flow_indices(m;connection=conn,direction=direction(:from_node))
            for (conn,n_to,d_to,s,t)  in connection_flow_indices(m;connection=conn,direction=direction(:to_node),t=t)
                if n_to != n_from
                    constr_dict[conn,n_from,t] = @constraint(
                        m,
                            connection_flow[conn,n_from,d_from,s,t]
                            -
                                connection_flow[conn,n_to,d_from,s,t]
                        ==
                        1/connection_reactance(connection=conn) ##reactance or susceptance
                        * connection_reactance_p_u(connection=conn)
                        * (node_voltage_angle[n_from,s,t]
                            -
                                    node_voltage_angle[n_to,s,t])
                    )
                end
            end
        end
    end
end
#TODO
