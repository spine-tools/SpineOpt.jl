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
    connections_invested_available_indices(connection=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `connections_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function connections_invested_available_indices(
    m::Model;
    connection=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=anything,
)
    connection = intersect(indices(candidate_connections), members(connection))
    connection_investment_stochastic_time_indices(
        m; connection=connection, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
    )
end

"""
    connections_invested_available_int(x)

Check if conneciton investment variable type is defined to be an integer.
"""

function connections_invested_available_int(x)
    connection_investment_variable_type(connection=x.connection) == :connection_investment_variable_type_integer
end

function _initial_connections_invested_available(; kwargs...)
    something(initial_connections_invested_available(; kwargs...), 0)
end

"""
    add_variable_connections_invested_available!(m::Model)

Add `connections_invested_available` variables to model `m`.
"""
function add_variable_connections_invested_available!(m::Model)
    add_variable!(
        m,
        :connections_invested_available,
        connections_invested_available_indices;
        lb=constant(0),
        int=connections_invested_available_int,
        fix_value=fix_connections_invested_available,
        initial_value=_initial_connections_invested_available,
        required_history_period=maximum_parameter_value(connection_investment_tech_lifetime),
    )
end
