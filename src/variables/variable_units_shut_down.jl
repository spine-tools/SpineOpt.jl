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
    add_variable_units_shut_down!(m::Model)

Add `units_shut_down` variables to model `m`.
"""
function add_variable_units_shut_down!(m::Model)
    add_variable!(
        m,
        :units_shut_down,
        units_switched_indices;
        lb=constant(0),
        bin=units_on_bin,
        int=units_on_int,
        replacement_value=units_switched_replacement_value,
        required_history_period=maximum_parameter_value(min_down_time),
    )
end
