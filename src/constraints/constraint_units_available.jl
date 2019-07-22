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
    constraint_available_units(m::Model)

Limit the units_online by the number of available units.
"""

function constraint_units_available(m::Model)
    @fetch units_available = m.ext[:variables]
    constr_dict = m.ext[:constraints][:units_available] = Dict()
    for (u, t) in var_units_on_indices()
        constr_dict[u, t] = @constraint(
            m,
            + units_available[u, t]
            ==
            + number_of_units(unit=u, t=t) * avail_factor(unit=u, t=t)
        )
    end
end
