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
    + reduce(
        +,
        flow[x] * tax_net_flow(;inds..., t=x.t) * duration(x.t)
        for inds in indices(tax_net_flow)
            for x in flow_indices(
                node=node_group__node(node_group=inds.node_group),
                commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                direction=:out);
        init=0
    )
    - reduce(
        +,
        flow[x] * tax_net_flow(;inds..., t=x.t) * duration(x.t)
        for inds in indices(tax_net_flow)
            for x in flow_indices(
                node=node_group__node(node_group=inds.node_group),
                commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                direction=:in);
        init=0
    )
    + reduce(
        +,
        flow[x] * tax_out_flow(;inds..., t=x.t) * duration(x.t)
        for inds in indices(tax_out_flow)
            for x in flow_indices(
                node=node_group__node(node_group=inds.node_group),
                commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                direction=:out);
        init=0
    )
    + reduce(
        +,
        flow[x] * tax_in_flow(;inds..., t=x.t) * duration(x.t)
        for inds in indices(tax_in_flow)
            for x in flow_indices(
                node=node_group__node(node_group=inds.node_group),
                commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                direction=:in);
        init=0
    )
end
