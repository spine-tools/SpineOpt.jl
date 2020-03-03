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
    add_constraint_max_cum_in_flow_bound!(m::Model)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow of
`commodity_group cg` into a `unit_group ug`
if `max_cum_in_flow_bound` exists for the combination of `cg` and `ug`.
"""
function add_constraint_max_cum_in_flow_bound!(m::Model)
    @fetch flow = m.ext[:variables]
    cons = m.ext[:constraints][:max_cum_in_flow_bound] = Dict()
    for (ug, cg) in indices(max_cum_in_flow_bound)
        cons[ug, cg] = @constraint(
            m,
            + sum(
                flow[u, n, c, d, t]
                for (u, n, c, d, t) in flow_indices(direction=direction(:from_node), unit=ug, commodity=cg)
            )
            <=
            + max_cum_in_flow_bound[(unit=ug, commodity=cg)]
        )
    end
end