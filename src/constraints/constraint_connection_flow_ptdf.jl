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
    @fetch connection_flow, node_injection = m.ext[:variables]
    constr_dict = m.ext[:constraints][:flow_ptdf] = Dict()
    for conn in connection(connection_monitored=:value_true, has_ptdf=true)
        for (conn, n_to, d, t) in connection_flow_indices(;
                connection=conn, last(connection__from_node(connection=conn))...
            ) # NOTE: always assume that the second (last) node in `connection__from_node` is the 'to' node
            constr_dict[conn, n_to, t] = @constraint(
                m,
                + connection_flow[conn, n_to, direction(:to_node), t]
                - connection_flow[conn, n_to, direction(:from_node), t]
                ==
                + expr_sum(
                    ptdf(connection=conn, node=n) * node_injection[n, t]
                    for (conn, n) in indices(ptdf; connection=conn);
                    init=0
                )
            )
        end
    end
end
