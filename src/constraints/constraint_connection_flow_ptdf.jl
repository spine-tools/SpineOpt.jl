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

For connection networks with monitored and has_ptdf set to true, set the steady state flow based on PTDFs
"""
function add_constraint_connection_flow_ptdf!(m::Model)
    @fetch connection_flow, unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:flow_ptdf] = Dict()
    for conn in connection(connection_monitored=:value_true, has_ptdf=:value_true)
        for (conn, n_to, d, t) in connection_flow_indices(;
                connection=conn, last(connection__from_node(connection=conn))...
            ) # NOTE: always assume that the second (last) node in `connection__from_node` is the 'to' node
            constr_dict[conn, n_to, t] = @constraint(
                m,
                + connection_flow[conn, n_to, direction(:to_node), t]
                - connection_flow[conn, n_to, direction(:from_node), t]
                ==
                + reduce(
                    +,
                    + ptdf(connection=conn, node=n_inj)
                    * (
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
                            unit_flow[u, n_inj, d, t_short] * duration(t_short)
                            for (u, n_inj, d, t_short) in unit_flow_indices(
                                node=n_inj, direction=direction(:to_node), t=t_in_t(t_long=t)
                            );
                            init=0
                        )
                        - reduce(
                            +,
                            unit_flow[u, n_inj, d, t_short] * duration(t_short)
                            for (u, n_inj, d, t_short) in unit_flow_indices(
                                node=n_inj, direction=direction(:from_node), t=t_in_t(t_long=t)
                            );
                            init=0
                        )
                    )
                    for (conn, n_inj) in indices(ptdf; connection=conn)
                    if !isapprox(ptdf(connection=conn, node=n_inj), 0; atol=node_ptdf_threshold(node=n_inj));
                    init=0
                )
            )
        end
    end
end
