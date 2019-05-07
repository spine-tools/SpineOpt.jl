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
    for inds in units_online_indices()
        min_up_time(;inds...) != 0 || continue
        @constraint(
            m,
            + units_online[inds]
            >=
            + sum(
                units_starting_up[x]
                for x in units_online_indices(unit=inds.unit)
                    if inds.t.start - min_up_time(;inds...) < x.t.start <= inds.t.start
            )
        )
    end
end
