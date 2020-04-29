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
    units_on_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function units_on_indices(;unit=anything, stochastic_scenario=anything, t=anything)
    [
        (unit=u, stochastic_scenario=s, t=t)
        for (u, s, t) in units_on_indices_rc(
            unit=unit,
            stochastic_scenario=stochastic_scenario,
            t=t,
            _compact=false
        )
    ]
end

fix_units_on_(x) = fix_units_on(unit=x.unit, t=x.t, _strict=false)
units_on_bin(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_binary
units_on_int(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_integer

function create_variable_units_on!(m::Model)
    create_variable!(m, :units_on, units_on_indices; lb=x -> 0, bin=units_on_bin, int=units_on_int)
end

fix_variable_units_on!(m::Model) = fix_variable!(m, :units_on, units_on_indices, fix_units_on_)
