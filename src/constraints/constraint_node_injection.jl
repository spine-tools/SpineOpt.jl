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
    add_constraint_node_injection(m::Model)

Set node injection equal to the net flow injection from units minus the demand. 
"""
function add_constraint_node_injection!(m::Model)
    @fetch node_injection, unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:node_injection] = Dict()
    for (n, t) in node_injection_indices()
        constr_dict[n, t] = @constraint(
            m,
            node_injection[n, t]
            ==
            + reduce(
                +,
                unit_flow[u, n, d, t_short] * duration(t_short)
                for (u, n, d, t_short) in unit_flow_indices(node=n, direction=direction(:to_node), t=t_in_t(t_long=t));
                init=0
            )
            - reduce(
                +,
                unit_flow[u, n, d, t_short] * duration(t_short)
                for (u, n, d, t_short) in unit_flow_indices(node=n, direction=direction(:from_node), t=t_in_t(t_long=t));
                init=0
            )
            - demand[(node=n, t=t)]
            - reduce(
                +,
                fractional_demand[(node1=ng, node2=n, t=t)] * demand[(node=ng, t=t)]
                for ng in node_group__node(node2=n);
                init=0
            )
        )
    end
end

