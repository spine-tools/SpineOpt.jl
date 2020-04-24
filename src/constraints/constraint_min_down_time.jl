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
    add_constraint_min_down_time!(m::Model)

Constraint start-up by minimum down time.
"""
function add_constraint_min_down_time!(m::Model)
    @fetch units_on, units_available, units_shut_down = m.ext[:variables]
    cons = m.ext[:constraints][:min_down_time] = Dict()
    for u in indices(min_down_time)
        for (u, t) in units_on_indices(unit=u)
            cons[u, t] = @constraint( # TODO: Stochastic path indexing required due to time delays, but first we'll have to decide how to determine the stochastic indices of `units`.
                m,
                + units_on[u, t]
                <=
                + units_available[u, t]
                - reduce(
                    +,
                    units_shut_down[u1, t1]
                    for (u1, t1) in units_on_indices(
                        unit=u, t=to_time_slice(TimeSlice(end_(t) - min_down_time(unit=u), end_(t))) # TODO: Stochastic parameters
                    );
                    init=0
                )
            )
        end
    end
end