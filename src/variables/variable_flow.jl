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
    flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `flow` variable.
The keyword arguments act as filters for each dimension.
"""
function flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (unit=u, node=n, commodity=c, direction=d, t=t1)
        for (u, n, c, d, tb) in flow_indices_rc(
            unit=unit, node=node, commodity=commodity, direction=direction, _compact=false
        )
        for t1 in time_slice(temporal_block=tb, t=t)
    ]
end

fix_flow_(x) = fix_flow(unit=x.unit, node=x.node, direction=x.direction, t=x.t, _strict=false)

create_variable_flow!(m::Model) = create_variable!(m, :flow, flow_indices; lb=x -> 0)
save_variable_flow!(m::Model) = save_variable!(m, :flow, flow_indices)
fix_variable_flow!(m::Model) = fix_variable!(m, :flow, flow_indices, fix_flow_)