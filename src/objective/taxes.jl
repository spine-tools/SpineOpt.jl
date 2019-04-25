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
    taxes(m::Model, flow)

Variable operation costs defined on flows.
"""
function taxes(flow)
    #@butcher
    let tax_costs = zero(AffExpr)
        for (u,n,d,block) in param_keys(vom_cost())
                tax_costs +=
                + reduce(
                    +,
                    flow[u, n, c, d, t] * tax_net_flow(commodity_group=cg1,node_group=ng1)(t=t) * duration(t)
                        for (cg1,ng1) in param_keys(tax_net_flow())
                            for (u, n, c, d, t) in flow_indices(node=node_group__node(node_group = ng1),commodity=commodity_group__commodity(commodity_group=cg1), direction=:out);
                    init=0
                )
                - reduce(
                    +,
                    flow[u, n, c, d, t] * tax_net_flow(commodity_group=cg1,node_group=ng1)(t=t) * duration(t)
                        for (cg1,ng1) in param_keys(tax_net_flow())
                            for (u, n, c, d, t) in flow_indices(node=node_group__node(node_group = ng1),commodity=commodity_group__commodity(commodity_group=cg1), direction=:in);
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c, d, t] * tax_out_flow(commodity_group=cg1,node_group=ng1)(t=t) * duration(t)
                        for (cg1,ng1) in param_keys(tax_out_flow())
                            for (u, n, c, d, t) in flow_indices(node=node_group__node(node_group = ng1),commodity=commodity_group__commodity(commodity_group=cg1), direction=:out);
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c, d, t] * tax_in_flow(commodity_group=cg1,node_group=ng1)(t=t) * duration(t)
                        for (cg1,ng1) in param_keys(tax_in_flow())
                            for (u, n, c, d, t) in flow_indices(node=node_group__node(node_group = ng1),commodity=commodity_group__commodity(commodity_group=cg1), direction=:in);
                    init=0
                )
        end
        tax_costs
    end
end
