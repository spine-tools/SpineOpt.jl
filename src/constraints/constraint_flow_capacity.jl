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
    constraint_flow_capacity(m::Model, flow, units_online)

Limit the maximum in/out `flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function constraint_flow_capacity(m::Model, flow, units_online)
    for inds in indices(unit_capacity)
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x] * duration(x.t)
                    for x in flow_indices(;
                        inds...,
                        commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                        t=t)
                )
                <=
                + sum(
                    units_online[x]
                        * unit_capacity(;inds..., t=x.t)
                        * unit_conv_cap_to_flow(;inds..., t=x.t)
                        * duration(x.t)
                    for x in units_online_indices(;inds..., t=t_in_t(t_long=t))
                )
            )
        end
    end
end
