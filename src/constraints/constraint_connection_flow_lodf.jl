#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


"""
    add_constraint_connection_flow_lodf!(m::Model)

Limit the post contingency flow on monitored connection mon to conn_emergency_capacity upon outage of connection cont.
"""
function add_constraint_connection_flow_lodf!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:connection_flow_lodf] = Dict()
    for (conn_mon, n_mon, d) in indices(connection_emergency_capacity)
        for (conn_cont, conn_mon) in indices(lodf; connection2=conn_mon)
            connction_flow_iter = Iterators.flatten(
                connection_flow_indices(; connection=conn, last(connection__from_node(connection=conn))...)
                for conn in (conn_cont, conn_mon)
            )
            for t in t_lowest_resolution(x.t for x in connction_flow_indices_iter)
                cons[conn_cont, conn_mon, t] = @constraint(
                    m,
                    # flow in monitored connection
                    + reduce(
                        +,
                        + connection_flow[conn_mon, n_mon_to, direction(:to_node), t_short]
                        - connection_flow[conn_mon, n_mon_to, direction(:from_node), t_short]
                        for (conn_mon, n_mon_to, d, t_short) in connection_flow_indices(;
                            connection=conn_mon, last(connection__from_node(connection=conn_mon))..., t=t_in_t(t_long=t)
                        ); # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                        init=0
                    )
                    # excess flow due to outage on contingency connection
                    + lodf(connection1=conn_cont, connection2=conn_mon)
                    * reduce(
                        +,
                        + connection_flow[conn_cont, n_cont_to, direction(:to_node), t_short]
                        - connection_flow[conn_cont, n_cont_to, direction(:from_node), t_short]
                        for (conn_cont, n_cont_to, d, t_short) in connection_flow_indices(;
                            connection=conn_cont, last(connection__from_node(connection=conn_cont))..., t=t_in_t(t_long=t)
                        ); # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
                        init=0
                    )
                    <=
                    + connection_emergency_capacity[(connection=conn_mon, node=n_mon, direction=d, t=t)]
                    * connection_availability_factor[(connection=conn_mon, t=t)]
                    * connection_conv_cap_to_flow[(connection=conn_mon, node=n_mon, direction=d, t=t)]
                )
            end
        end
    end
end
