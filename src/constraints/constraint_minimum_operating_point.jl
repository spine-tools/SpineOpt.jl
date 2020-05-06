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
    add_constraint_minimum_operating_point!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, unit_availability_factor` exist.
"""

function add_constraint_minimum_operating_point!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:minimum_operating_point] = Dict()
    for (u, n, d) in indices(minimum_operating_point)
        for (u, n, d, t) in unit_flow_indices(unit=u, node=n, direction=d)
            cons[u, n, d, t] = @constraint(
                m,
                unit_flow[u, n, d, t] * duration(t)
                >=
                + sum(
                    + units_on[u, t1] * min(duration(t), duration(t1))
                    for (u,t1) in units_on_indices(unit=u, t=t_overlaps_t(t))
                    )
                * minimum_operating_point[(unit=u, node=n, direction=d, t=t)]
                * unit_capacity[(unit=u, node=n, direction=d, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
            )
        end
    end
end
