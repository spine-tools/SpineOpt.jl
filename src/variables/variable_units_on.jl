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
    units_on_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function units_on_indices(;unit=anything, t=anything)
    unit = expand_unit_group(unit)
    (
        (unit=u, t=t1)
        for (u, tb) in units_on_indices_rc(unit=unit, _compact=false)
        for t1 in time_slice(temporal_block=tb, t=t)
    )
end


units_on_bin(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_binary
units_on_int(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_integer

function add_variable_units_on!(m::Model)
    add_variable!(
    	m,
    	:units_on, units_on_indices;
    	lb=x -> 0,
    	bin=units_on_bin,
    	int=units_on_int,
    	fix_value=x -> fix_units_on(unit=x.unit, t=x.t, _strict=false)
    )
end
