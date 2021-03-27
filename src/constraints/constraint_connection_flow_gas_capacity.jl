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
    constraint_gas_line_pack_capacity(m::Model)

This constraint is needed to force uni-directional unit_flow
"""
function add_constraint_connection_flow_gas_capacity!(m::Model)
    @fetch connection_flow,binary_connection_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:connection_flow_gas_capacity] = Dict()
    for (conn, n, d, s, t) in connection_flow_indices(m;node=node__commodity(commodity=commodity(:Gas)),direction=direction(:to_node))
        if has_state(node=n) == false
            constr_dict[conn, n, t] = @constraint(
                m,
                (
                    connection_flow[conn, n, d, s, t]
                    +  reduce(
                    +,
                    connection_flow[conn1, n1, d1, s1, t1]
                        for (conn1,n1,d1,s1,t1) in connection_flow_indices(m,connection=conn,t=t)
                            if d1 != d && n1 != n && has_state(node=n1) == false;
                                init=0
                        )
                ) /2
                <=
                + bigM(model=m.ext[:instance])
                * binary_connection_flow[conn, n, d, s, t]
            )
        end
    end
end
