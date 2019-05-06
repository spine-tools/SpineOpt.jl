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
    constraint_commitment_variables(m::Model, units_online, units_shutting_down, units_starting_up)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

function constraint_commitment_variables(m::Model, units_online, units_shutting_down, units_starting_up)
    for (u, t) in units_online_indices(), t2 in t_before_t(t_after=t)
        all(
        !isempty(t2) && t2 in [t for (u,t) in units_online_indices(unit=u)]
        ) || continue
        @constraint(
            m,
            + units_online[u,t2] - units_online[u,t]
            + units_starting_up[u,t] - units_shutting_down[u,t]
            ==
            0
        )
    end
end
