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
    add_constraint_connection_flow_ptdf(m::Model)

For commodity networks with commodity physics set to commodity_physics_opf_ptdf or commodity_physics_scopf_ptdf_lodf, set the
steady state flow based on PTDFs

"""
function add_constraint_connection_flow_ptdf!(m::Model, ptdf_conn_n, net_inj_nodes)
    @fetch connection_flow, unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:flow_ptdf] = Dict()
    for conn in connection(connection_monitored=:true)
        n_from = first(connection__from_node(connection=conn, direction=direction(:from_node)))
        n_to=n_from
        for n in connection__to_node(connection=conn, direction=direction(:to_node))
            if !(n == n_from)
                n_to = n
                break
            end
        end        
        for c in node__commodity(node=n_to)
            if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
                for (conn, n_to, d, t) in connection_flow_indices(connection=conn,node=n_to, direction=direction(:to_node))
                    constr_dict[conn, t] = @constraint(
                        m,
                        + connection_flow[conn, n_to, direction(:to_node), t]
                        - connection_flow[conn, n_to, direction(:from_node), t]
                        ==
                        + reduce(
                            +,
                            + ptdf_conn_n[(conn,n_inj)] * (
                                # explicit node demand
                                - demand[(node=n_inj, t=t)]
                                # demand defined by fractional_demand
                                - reduce(
                                    +,
                                    fractional_demand[(node1=ng, node2=n_inj, t=t)] * demand[(node=ng, t=t)]
                                    for ng in node_group__node(node2=n_inj);
                                    init=0
                                )
                                # Flows from units
                                + reduce(
                                    +,
                                    unit_flow[u, n_inj, direction(:to_node), t]
                				    for u in unit__to_node(node=n_inj, direction=direction(:to_node));
                                    init=0
                                )
                                - reduce(
                                    +,
                                    unit_flow[u, n_inj, direction(:from_node), t]
                				    for u in unit__from_node(node=n_inj, direction=direction(:from_node));
                                    init=0
                                )
                            )
# for n_inj in net_inj_nodes if abs(ptdf_conn_n[(conn,n_inj)]) > commodity_ptdf_threshold[(commodity=c)];
# TODO Why does enabling the previous line result in an error?
                            for n_inj in net_inj_nodes if abs(ptdf_conn_n[(conn,n_inj)]) > 0.0001;
                            init=0
                        )
                    )
                end
            end
        end
    end
end
