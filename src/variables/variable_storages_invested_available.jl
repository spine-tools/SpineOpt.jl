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
    storages_invested_available_indices(node=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `storagess_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function storages_invested_available_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=anything,
)
    node = intersect(indices(candidate_storages), members(node))
    node_investment_stochastic_time_indices(
        m; node=node, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
    )
end

"""
    storages_invested_available_int(x)

Check if storage investment variable type is defined to be an integer.
"""

function storages_invested_available_int(x)
    storage_investment_variable_type(node=x.node) == :storage_investment_variable_type_integer
end

function _initial_storages_invested_available(; kwargs...)
    something(initial_storages_invested_available(; kwargs...), 0)
end

"""
    add_variable_storages_invested_available!(m::Model)

Add `storages_invested_available` variables to model `m`.
"""
function add_variable_storages_invested_available!(m::Model)
    add_variable!(
        m,
        :storages_invested_available,
        storages_invested_available_indices;
        lb=constant(0),
        int=storages_invested_available_int,
        fix_value=fix_storages_invested_available,
        initial_value=_initial_storages_invested_available,
        required_history_period=maximum_parameter_value(storage_investment_tech_lifetime),
    )
end
