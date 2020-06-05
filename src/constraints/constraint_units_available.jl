#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


"""
    add_constraint_units_available!(m::Model)

Limit the units_online by the number of available units.
"""

function add_constraint_units_available!(m::Model)
    @fetch units_available = m.ext[:variables]
    cons = m.ext[:constraints][:units_available] = Dict()
    for (u, s, t) in units_on_indices()
        cons[u, s, t] = @constraint(
            m,
            + units_available[u, s, t]
            ==
            + number_of_units[(unit=u, t=t)] * unit_availability_factor[(unit=u, t=t)] # TODO: Stochastic parameters
        )
    end
end