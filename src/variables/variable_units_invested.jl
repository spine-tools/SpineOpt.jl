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
    add_variable_units_invested!(m::Model)

Add `units_invested` variables to model `m`.
"""
function add_variable_units_invested!(m::Model)
    add_variable!(
        m,
        :units_invested,
        units_invested_available_indices;
        lb=constant(0),
        int=units_invested_available_int,
        fix_value=fix_units_invested,
        initial_value=initial_units_invested,
        required_history_period=maximum_parameter_value(unit_investment_tech_lifetime),
    )
end
