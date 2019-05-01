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
    function constraint_min_up_time(m::Model, units_online, units_available, units_starting_up)

Constraint running by minimum up time.
"""

function constraint_min_up_time(m::Model, units_online, units_starting_up)
    for (u,t) in units_online_indices()
        all(min_down_time(unit=u)!=0) || continue
        @constraint(
            m,
            units_online[u,t]
            >=
            + sum(
            units_starting_up[u1,t1]
            for (u1,t1) in units_online_indices(unit=u) if t1.start > t.start-min_up_time(unit=u) && t1.start <= t.start
            )
        )
    end
end
