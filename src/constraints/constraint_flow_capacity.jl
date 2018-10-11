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
    for (c, n, u, d) in commodity__node__unit__direction(), t=1:number_of_timesteps(time="timer")
        all([
            unit_capacity(unit=u, commodity=c) != nothing,
            number_of_units(unit=u) != nothing,
            unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
            avail_factor(unit=u, t=t) != nothing
        ]) || continue
        @constraint(
            m,
            + flow[c, n, u, d, t]
            <=
            + avail_factor(unit=u, t=t)
                * unit_capacity(unit=u, commodity=c)
                    * number_of_units(unit=u)
                        * unit_conv_cap_to_flow(unit=u, commodity=c)
        )
    end
end
