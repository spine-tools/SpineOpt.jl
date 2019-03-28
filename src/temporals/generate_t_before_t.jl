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
    generate_t_before_t(m::Model)

A tuple returned for a specific timeslice t', returning all timeslices t'' directly before t'.
"""
function generate_t_before_t(timeslices,details)
    @butcher t_before_t = Dict()
    for i in timeslices
        t_before_t[i] = Dict()
        for j in timeslices
            if details[j][2] == details[i][1]
                t_before_t = push!(t_before_t,Tuple([timeslices[i], timeslices[j]]))
            end
        end
    end
    t_before_t
end
