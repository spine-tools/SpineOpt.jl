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
    constraint_minimum_operating_point(m::Model)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

function constraint_minimum_operating_point(m::Model)
    @fetch flow, units_on = m.ext[:variables]
    constr_dict = m.ext[:constraints][:minimum_operating_point] = Dict()
    for (u, cg) in indices(minimum_operating_point)
        for (u, cg, d) in indices(unit_capacity; unit=u, commodity_group=cg)
            for (u, t) in var_units_on_indices(unit=u)
                constr_dict[u, cg, d, t] = @constraint(
                    m,
                    + sum(
                        flow[u1, n, c, d1, t1]
                            for (u1, n, c, d1, t1) in flow_indices(
                                commodity=commodity_group__commodity(commodity_group=cg),
                                unit=u,
                                direction = d,
                                t=t
                            )
                    )
                    >=
                    + units_on[u, t]
                        * minimum_operating_point(unit=u, commodity_group=cg, t=t)
                            * number_of_units(unit=u)
                                * unit_capacity(unit=u, commodity_group=cg, direction=d)
                                    * unit_conv_cap_to_flow(unit=u, commodity_group=cg)
                )
            end
        end
    end
end
