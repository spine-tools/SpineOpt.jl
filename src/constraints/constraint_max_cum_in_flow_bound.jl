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
    constraint_max_cum_in_flow_bound(m::Model, flow)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow of
`commodity_group cg` into a `unit_group ug`
if `max_cum_in_flow_bound` exists for the combination of `cg` and `ug`.
"""
function constraint_max_cum_in_flow_bound(m::Model, flow)
    for inds in indices(max_cum_in_flow_bound)
        @constraint(
            m,
            + reduce(
                +,
                flow[x]
                for x in flow_indices(;
                    inds...,
                    unit=unit_group__unit(unit_group=inds.unit_group),
                    commodity=commodity_group__commodity(commodity_group=inds.commodity_group)
                );
                init=0
            )
            <=
            + max_cum_in_flow_bound(;inds...)
        )
    end
end
