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
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_flow_capacity] = Dict()
    for (u, n, d) in indices(unit_capacity)
        for (u, n, d, t) in unit_flow_indices(unit=u, node=n, direction=d)
            cons[u, n, d, t] = @constraint(
                m,
                unit_flow[u, n, d, t] * duration(t)
                <=
                + unit_capacity[(unit=u, node=n, direction=d, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
                * reduce(
                    +,
                    units_on[u1, t1] * duration(t1)
                    for (u1, t1) in units_on_indices(unit=u, t=t_in_t(t_long=t));
                    init=0
                )
            )
        end
    end
end