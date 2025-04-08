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

function units_out_of_service_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = intersect(unit, _unit_with_out_of_service_variable())
    unit_stochastic_time_indices(
        m; unit=unit, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block,
    )
end

"""
    _unit_with_out_of_service_variable()

An `Array` of units that need `units_out_of_service`, `units_taken_out_of_service` and `units_returned_to_service`.
"""
_unit_with_out_of_service_variable() = unit(has_out_of_service_variable=true)

"""
    units_out_of_service_bin(x)

Check if unit online variable type is defined as a binary.
"""
units_out_of_service_bin(x) = outage_variable_type(unit=x.unit) == :unit_online_variable_type_binary

"""
    units_out_of_service_int(x)

Check if unit online variable type is defined as an integer.
"""
units_out_of_service_int(x) = outage_variable_type(unit=x.unit) == :unit_online_variable_type_integer

"""
    add_variable_units_out_of_service!(m::Model)

Add `units_out_of_service` variables to model `m`.
"""
function add_variable_units_out_of_service!(m::Model)
    add_variable!(
        m,
        :units_out_of_service,
        units_out_of_service_indices;
        lb=constant(0),
        bin=units_out_of_service_bin,
        int=units_out_of_service_int,
        fix_value=fix_units_out_of_service,
        initial_value=initial_units_out_of_service,
        required_history_period=maximum_parameter_value(scheduled_outage_duration),        
    )
end

function _get_units_out_of_service(m, u, s, t)
    get(m.ext[:spineopt].variables[:units_out_of_service], (u, s, t), 0)
end
