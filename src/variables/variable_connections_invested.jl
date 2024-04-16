#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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
    add_variable_connections_invested!(m::Model)

Add `connections_invested` variables to model `m`.
"""
function add_variable_connections_invested!(m::Model)
    add_variable!(
        m,
        :connections_invested,
        connections_invested_available_indices;
        lb=constant(0),
        fix_value=fix_connections_invested,
        initial_value=initial_connections_invested,
        int=connections_invested_available_int,
        required_history_period=maximum_parameter_value(connection_investment_lifetime),
    )
end
