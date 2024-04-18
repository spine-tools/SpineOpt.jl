#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    units_on_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable where the keyword arguments act as filters
for each dimension.
"""
function units_on_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = intersect(unit, _activatable_unit())
    (
        (unit=u, stochastic_scenario=s, t=t)
        for (u, s, t) in unit_stochastic_time_indices(
            m; unit=unit, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

"""
    units_switched_indices(m; <keyword arguments>)

Indices for the `units_started_up` and `units_shut_down`.
"""
function units_switched_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = intersect(unit, _switchable_unit())
    (
        (unit=u, stochastic_scenario=s, t=t)
        for (u, s, t) in unit_stochastic_time_indices(
            m; unit=unit, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

"""
    _activatable_unit()

An `Array` of units that need a `units_on` variable.
"""
_activatable_unit() = unit(is_activatable=true)

"""
    _switchable_unit()

An `Array` of units that need a `units_started_up` and `units_shut_down` variables.
"""
_switchable_unit() = unit(is_switchable=true)

"""
    units_on_bin(x)

Check if unit online variable type is defined as a binary.
"""
units_on_bin(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_binary

"""
    units_on_int(x)

Check if unit online variable type is defined as an integer.
"""
units_on_int(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_integer

function units_on_replacement_value(ind)
    if online_variable_type(unit=ind.unit) == :unit_online_variable_type_none
        number_of_units[(; ind...)]
    else
        nothing
    end
end

function units_switched_replacement_value(ind)
    if online_variable_type(unit=ind.unit) == :unit_online_variable_type_none
        Call(0)
    else
        nothing
    end
end

"""
    add_variable_units_on!(m::Model)

Add `units_on` variables to model `m`.
"""
function add_variable_units_on!(m::Model)
    add_variable!(
        m,
        :units_on,
        units_on_indices;
        lb=constant(0),
        bin=units_on_bin,
        int=units_on_int,
        fix_value=fix_units_on,
        initial_value=initial_units_on,
        replacement_value=units_on_replacement_value,
        non_anticipativity_time=units_on_non_anticipativity_time,
        non_anticipativity_margin=units_on_non_anticipativity_margin,
        required_history_period=_get_max_duration(m, [min_up_time, min_down_time]),
    )
end

function _get_units_on(m, u, s, t)
    get(m.ext[:spineopt].variables[:units_on], (u, s, t)) do
        number_of_units(m; unit=u, stochastic_scenario=s, analysis_time=_analysis_time(m), t=t)
    end
end
