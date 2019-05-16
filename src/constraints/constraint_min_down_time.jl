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
    constraint_min_down_time(m::Model)

Constraint start-up by minimum down time.
"""

@catch_undef function constraint_min_down_time(m::Model)
    @fetch units_on, units_available, units_shut_down = m.ext[:variables]
    constr_dict = m.ext[:constraints][:min_down_time] = Dict()
    for (u, t) in units_on_indices()
        if min_down_time(unit=u) != 0
            constr_dict[u, t] = @constraint(
                m,
                units_on[u, t]
                <=
                + units_available[u, t]
                - sum(
                    units_shut_down[u1, t1]
                    for (u1, t1) in units_on_indices(unit=u)
                        if t.start - min_down_time(unit=u) < t1.start <= t.start
                )
            )
        end
    end
end
