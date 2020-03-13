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

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

function add_constraint_minimum_operating_point!(m::Model)
    @fetch flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:minimum_operating_point] = Dict()
    for (u, d) in indices(minimum_operating_point)
        for (u, d) in indices(unit_capacity; unit=u, direction=d)
            for (u, t) in units_on_indices(unit=u)
                cons[u, d, t] = @constraint(
                    m,
                    + sum(
                        flow[u_, n, d_, t1]
                        for (u_, n, d_, t1) in flow_indices(unit=u, direction=d, t=t)
                    )
                    >=
                    + units_on[u, t]
                    * minimum_operating_point[(unit=u, direction=d, t=t)]
                    * unit_capacity[(unit=u, direction=d, t=t)]
                    * unit_conv_cap_to_flow[(unit=u, direction=d, t=t)]
                )
            end
        end
    end
end