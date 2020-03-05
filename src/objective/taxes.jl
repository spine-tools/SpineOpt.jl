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
    taxes(m::Model)

"""
function taxes(m::Model)
    @fetch flow = m.ext[:variables]
    @expression(
        m,
        + reduce(
            +,
            flow[u, n, c, d, t] * tax_net_flow[(commodity=c1, node=n1, t=t)] * duration(t)
            for (c1, n1) in indices(tax_net_flow)
            for (u, n, c, d, t) in flow_indices(node=n1, commodity=c1, direction=direction(:to_node));
            init=0
        )
        - reduce(
            +,
            flow[u, n, c, d, t] * tax_net_flow[(commodity=c1, node=n1, t=t)] * duration(t)
            for (c1, n1) in indices(tax_net_flow)
            for (u, n, c, d, t) in flow_indices(node=n1, commodity=c1, direction=direction(:from_node));
            init=0
        )
        + reduce(
            +,
            flow[u, n, c, d, t] * tax_out_flow[(commodity=c1, node=n1, t=t)] * duration(t)
            for (c1, n1) in indices(tax_out_flow)
            for (u, n, c, d, t) in flow_indices(node=n1, commodity=c1, direction=direction(:from_node));
            init=0
        )
        + reduce(
            +,
            flow[u, n, c, d, t] * tax_in_flow[(commodity=c1, node=n1, t=t)] * duration(t)
            for (c1, n1) in indices(tax_out_flow)
            for (u, n, c, d, t) in flow_indices(node=n1, commodity=c1, direction=direction(:to_node));
            init=0
        )
    )
end
