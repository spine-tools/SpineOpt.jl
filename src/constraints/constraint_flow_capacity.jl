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
    add_constraint_flow_capacity!(m::Model)

Limit the maximum in/out `flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_flow_capacity!(m::Model)
    @fetch flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:flow_capacity] = Dict()
    for (u, c, d) in indices(unit_capacity)
        for t in time_slice()
            cons[u, c, d, t] = @constraint(
                m,
                + reduce(
                    +,
                    flow[u1, n1, c1, d1, t1] * duration(t1)
                    for (u1, n1, c1, d1, t1) in flow_indices(unit=u, commodity=c, direction=d, t=t);
                    init=0
                )
                <=
                + unit_capacity(unit=u, commodity=c, direction=d, t=t)
                * unit_conv_cap_to_flow(unit=u, commodity=c, t=t)
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

function update_constraint_flow_capacity!(m::Model)
    @fetch units_on = m.ext[:variables]
    cons = m.ext[:constraints][:flow_capacity]
    for (u, c, d) in indices(unit_capacity)
        for t in time_slice()
            for (u1, t1) in units_on_indices(unit=u, t=t_in_t(t_long=t))
                set_normalized_coefficient(
                    cons[u, c, d, t],
                    units_on[u1, t1],
                    - unit_capacity(unit=u, commodity=c, direction=d, t=t)
                    * unit_conv_cap_to_flow(unit=u, commodity=c, t=t)
                    * duration(t1)
                )
            end
        end
    end
end