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
    shut_down_costs(m::Model)

Shutdown cost term for units.
"""
function shut_down_costs(m::Model)
    @fetch units_shut_down = m.ext[:variables]
    @expression(
        m,
        reduce(
            +,
            shut_down_cost(unit=u) * units_shut_down[u, t]
            for (u, t) in units_on_indices() if shut_down_cost(unit=u) != nothing;
            init=0
        )
    )
end
