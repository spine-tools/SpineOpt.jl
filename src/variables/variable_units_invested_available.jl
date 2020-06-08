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
    units_invested_available_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""

function units_invested_available_indices(;unit=anything, stochastic_scenario=anything, t=anything)
    [
        (unit=u, stochastic_scenario=s, t=t)
        for (u, tb) in units_invested_available_indices_rc(unit=unit, _compact=false)
        for (u, s, t) in unit_investment_stochastic_time_indices(
            unit=u, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
    ]
end

units_invested_available_int(x) = unit_investment_variable_type(unit=x.unit) == :unit_investment_variable_type_integer

function add_variable_units_invested_available!(m::Model)
    add_variable!(
    	m,
    	:units_invested_available, units_invested_available_indices;
    	lb=x -> 0,
    	int=units_invested_available_int,
    	fix_value=x -> fix_units_invested_available(unit=x.unit, t=x.t, _strict=false)
    )
end

