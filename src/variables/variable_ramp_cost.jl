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
    ramp_cost_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""

function ramp_cost_indices(;unit=anything, t=anything)
    [
        (unit=u, t=t_)
        for u in intersect(SpineModel.unit(), unit)
        for t_ in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, t=t)))
    ]
end

create_variable_ramp_cost!(m::Model) = create_variable!(m, :ramp_cost, ramp_cost_indices; lb=x -> 0)
# fix_variable_flow!(m::Model) = fix_variable!(m, :flow, flow_indices, fix_flow_)
