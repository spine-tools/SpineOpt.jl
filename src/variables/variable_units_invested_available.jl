#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    units_invested_available_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function units_invested_available_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=anything,
)
    unit = intersect(indices(candidate_units), members(unit))
    unit_investment_stochastic_time_indices(
        m; unit=unit, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
    )
end

"""
    units_invested_available_int(x)

Check if unit investment variable type is defined to be an integer.
"""

units_invested_available_int(x) = unit_investment_variable_type(unit=x.unit) == :unit_investment_variable_type_integer

function _initial_units_invested_available(; kwargs...)
    something(initial_units_invested_available(; kwargs...), 0)
end

"""
    add_variable_units_invested_available!(m::Model)

Add `units_invested_available` variables to model `m`.
"""
function add_variable_units_invested_available!(m::Model)
    add_variable!(
        m,
        :units_invested_available,
        units_invested_available_indices;
        lb=constant(0),
        int=units_invested_available_int,
        fix_value=fix_units_invested_available,
        initial_value=_initial_units_invested_available,
        required_history_period=maximum_parameter_value(unit_investment_tech_lifetime),
    )
end
