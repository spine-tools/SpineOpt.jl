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
    for (u, cg) in minimum_operating_point_indices(), (u,t) in units_online_indices(unit=u)
        @constraint(
            m,
            + sum(
                flow[u1, n, c, d, t1]
                    for (u1,n,c,d,t1) in flow_indices(
                        commodity = commodity_group__commodity(commodity_group=cg),
                        unit=u,
                        t=t
                        )
                )
            >=
            + minimum_operating_point(unit=u, commodity_group=cg, t=t)
                * units_online[u, t]
                    * number_of_units(unit=u)
                            * sum(
                            unit_capacity(unit=u1,commodity=c1,direction=d1)
                              * unit_conv_cap_to_flow(unit=u1, commodity=c1)
                            for (u1,c1,d1) in unit_capacity_indices(
                                unit=u,
                                commodity = commodity_group__commodity(commodity_group=cg),
                                _indices = :all
                                )
                            )
        )
    end
end
