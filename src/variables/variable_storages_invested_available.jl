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
    node=members(node)
    (
        (node=n, stochastic_scenario=s, t=t)
        for (n, tb) in node__investment_temporal_block(
            node=intersect(indices(candidate_storages), node), temporal_block=temporal_block, _compact=false
        )
        for (n, s, t) in node_investment_stochastic_time_indices(
            m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
    )
end

"""
    storages_invested_available_int(x)

Check if storage investment variable type is defined to be an integer.
"""

function storages_invested_available_int(x)
    storage_investment_variable_type(node=x.node) == :storage_investment_variable_type_integer
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
        lb=Constant(0),
        int=storages_invested_available_int,
        fix_value=fix_storages_invested_available,
        internal_fix_value=internal_fix_storages_invested_available,
        initial_value=initial_storages_invested_available,
    )
end
