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
    constraint_minimum_operating_point(m::Model, flow)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

function constraint_minimum_operating_point(m::Model, flow, units_online)
    for inds in indices(minimum_operating_point)
        for cap_inds in indices(unit_capacity; inds...)
            for x in units_online_indices(;inds...)
                @constraint(
                    m,
                    + sum(
                        flow[y]
                        for y in flow_indices(;
                            inds...,
                            cap_inds...,
                            x...,
                            commodity=commodity_group__commodity(commodity_group=inds.commodity_group),
                        )
                    )
                    >=
                    + units_online[x]
                        * minimum_operating_point(;inds..., x...)
                        * unit_capacity(;cap_inds..., x...)
                        * unit_conv_cap_to_flow(;cap_inds..., x...)
                )
            end
        end
    end
end
