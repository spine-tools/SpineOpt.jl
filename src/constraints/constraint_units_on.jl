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
    add_constraint_units_on!(m::Model, units_on, units_available)

Limit the units_on by the number of available units.
"""

function add_constraint_units_on!(m::Model)
    @fetch units_on, units_available = m.ext[:variables]
    constr_dict = m.ext[:constraints][:units_on] = Dict()
    for (u, t) in units_on_indices() # TODO: Stochastic `unit` indexing
        constr_dict[u, t] = @constraint(
            m,
            + units_on[u, t]
            <=
            + units_available[u, t]
        )
    end
end