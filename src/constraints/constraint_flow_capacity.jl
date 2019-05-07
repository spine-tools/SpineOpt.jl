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
    constraint_flow_capacity(m::Model, flow)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

function constraint_flow_capacity(m::Model, flow)
    for (u, c, d) in unit_capacity_indices(),(u, n, c, d, t) in flow_indices(
            unit=u, commodity=c, direction=d)
        all([
            number_of_units(unit=u) != nothing,
            unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
            avail_factor(unit=u) != nothing
        ]) || continue
        @constraint(
            m,
            + flow[u, n, c, d, t]
            <=
            + avail_factor(unit=u)
                * unit_capacity(unit=u, commodity=c, direction=d)
                    * number_of_units(unit=u)
                        * unit_conv_cap_to_flow(unit=u, commodity=c)
        )
    end
end

"""
    constraint_flow_capacity(m::Model, flow, units_online)

Limit the maximum in/out `flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
function constraint_flow_capacity(m::Model, flow, units_online)
<<<<<<< Updated upstream
    for (u, cg, d) in unit_capacity_indices(), t in time_slice()
        @constraint(
            m,
            + sum(
                flow[u1, n1, c1, d1, t1] * duration(t1)
                    for (u1, n1, c1, d1, t1) in flow_indices(
                            unit=u, commodity=commodity_group__commodity(commodity_group = cg), direction=d, t=t)
            )
            <=
            + sum(
                units_online[u1, t1]
                    * unit_capacity(unit=u, commodity_group=cg, direction=d)
                        * unit_conv_cap_to_flow(unit=u, commodity_group=cg)
                            *duration(t1)
                                    for (u1,t1) in units_online_indices(unit=u)
                                        if t1 in t_in_t(t_long=t)
=======
    for (u, c, d) in unit_capacity_indices(), t in time_slice()
        unit_conv_cap_to_flow(unit=u, commodity=c) != nothing || continue
        @constraint(
            m,
            + sum(
                + flow[u1, n1, c1, d1, t1] * duration(t1)
                for (u1, n1, c1, d1, t1) in flow_indices(unit=u, commodity=c, direction=d, t=t)
            )
            <=
            + sum(
                + units_online[u1, t1]
                    * unit_capacity(unit=u, commodity=c, direction=d)
                    * unit_conv_cap_to_flow(unit=u, commodity=c)
                    * duration(t1)
                for (u1, t1) in units_online_indices(unit=u)
                    if t1 in t_in_t(t_long=t)
>>>>>>> Stashed changes
            )
        )
    end
end
