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
    for inds in indices(min_up_time; value_filter=v->v!=0)
        for x in units_online_indices(;inds...)
            @constraint(
                m,
                + units_online[x]
                >=
                + sum(
                    units_starting_up[y]
                    for y in units_online_indices(;inds...)
                        if y.t.start - min_up_time(;inds...) < x.t.start <= y.t.start
                )
            )
        end
    end
end
