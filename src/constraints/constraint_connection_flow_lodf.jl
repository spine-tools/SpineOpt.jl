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
    add_constraint_connection_flow_capacity!(m::Model)

Limit the post contingency flow on monitored connection mon to conn_emergency_capacity upon outage of connection con.
"""
function add_constraint_connection_flow_lodf!(m::Model, lodf_con_mon, con__mon)
    @fetch connection_flow = m.ext[:variables]
    cons = m.ext[:constraints][:connection_flow_lodf] = Dict()
    for (con,mon) in con__mon
        for (mon_, n_mon, d, s, t) in connection_flow_indices(connection=mon, direction=direction(:to_node))
            for n_con in connection__to_node(connection=con,direction=direction(:to_node))
                cons[con, mon, s, t] = @constraint( # TODO: This constraint seems to function between multiple nodes, so stochastic path indexing will be required...
                    m,
                     + connection_flow[mon, n_mon, direction(:to_node), s, t]
                     - connection_flow[mon, n_mon, direction(:from_node), s, t]
                     + lodf_con_mon[(con,mon)]*connection_flow[con, n_con, direction(:to_node), s, t]
                     - lodf_con_mon[(con,mon)]*connection_flow[con, n_con, direction(:from_node), s, t]
                    <=
                    + connection_emergency_capacity[(connection=mon, node=n_mon, direction=d, t=t)] # TODO: Stochastic parameters
                    * connection_availability_factor[(connection=mon, t=t)]
                    * connection_conv_cap_to_flow[(connection=mon, node=n_mon, direction=d, t=t)]
                )
            end
        end
    end
end
