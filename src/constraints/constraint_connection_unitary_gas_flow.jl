
1#############################################################################
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
    add_constraint_connection_unitary_gas_flow!(m::Model)

This constraint is needed to force uni-directional flow over gas connections.
"""
function add_constraint_connection_unitary_gas_flow!(m::Model)
    @fetch binary_gas_connection_flow = m.ext[:variables]
    m.ext[:constraints][:connection_unitary_gas_flow] = Dict(
    (connection=conn, node1=n1, node2=n2, stochastic_scenario=s,t=t) => @constraint(
            m,
            sum(
                binary_gas_connection_flow[conn, n1, d, s,t]
                for (conn,n1,d,s,t) in connection_flow_indices(m;connection=conn,node=n1,stochastic_scenario=s,direction=direction(:to_node),t=t_in_t(m;t_long=t))
            )/length(connection_flow_indices(m;connection=conn,node=n1,stochastic_scenario=s,direction=direction(:to_node),t=t_in_t(m;t_long=t)))
            ==
            1 -
            sum(
                binary_gas_connection_flow[conn, n2, direction(:to_node), s,t]
                for (conn,n2,d,s,t) in connection_flow_indices(m;connection=conn,node=n2,stochastic_scenario=s,direction=direction(:to_node),t=t_in_t(m;t_long=t))
            )/length(connection_flow_indices(m;connection=conn,node=n2,stochastic_scenario=s,direction=direction(:to_node),t=t_in_t(m;t_long=t)))
    ) for (conn, n1, n2, s, t) in constraint_connection_flow_gas_capacity_indices(m)
    )
end
