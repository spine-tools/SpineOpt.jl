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
    units_out_of_service_bin(x)

Check if unit online variable type is defined as a binary.
"""
units_out_of_service_bin(x) = outage_variable_type(unit=x.unit) == :unit_online_variable_type_binary

"""
    units_out_of_service_int(x)

Check if unit online variable type is defined as an integer.
"""
units_out_of_service_int(x) = outage_variable_type(unit=x.unit) == :unit_online_variable_type_integer

function units_out_of_service_replacement_value(ind)
    if outage_variable_type(unit=ind.unit, _default=:unit_online_variable_type_none) == :unit_online_variable_type_none
        units_unavailable[(; ind...)]
    else
        nothing
    end
end

function units_out_of_service_switched_replacement_value(ind)
    if outage_variable_type(unit=ind.unit, _default=:unit_online_variable_type_none) == :unit_online_variable_type_none
        Call(0)
    else
        nothing
    end
end


"""
    add_variable_units_out_of_service!(m::Model)

Add `units_out_of_service` variables to model `m`.
"""
function add_variable_units_out_of_service!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :units_out_of_service,
        units_on_indices;
        lb=Constant(0),
        bin=units_out_of_service_bin,
        int=units_out_of_service_int,
        fix_value=fix_units_out_of_service,
        initial_value=initial_units_out_of_service,
        replacement_value=units_out_of_service_replacement_value,        
    )
end
