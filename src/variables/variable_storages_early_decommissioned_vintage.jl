#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
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
    storages_early_decommissioned_vintage_indices(node=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `storages_early_decommissioned_vintage` variable where
the keyword arguments act as filters for each dimension.
"""
function storages_early_decommissioned_vintage_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t_vintage=anything,
    t=anything,
    temporal_block=anything,
)
    node = members(node)
    unique([
        (node=u, stochastic_scenario=s, t_vintage=t_v, t=t)
        for (u, tb) in node__investment_temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for (u, s, t_v) in node_investment_stochastic_time_indices(
            m;
            node=u,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t_vintage,
        )
        for (u, s, t) in node_investment_stochastic_time_indices(
            m;
            node=u,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
        if storages_early_decommissioning(node=u) && t >= t_v #FIXME
    ])
end

"""
    add_variable_storages_early_decommissioned_vintage!(m::Model)

Add `storages_early_decommissioned_vintage` variables to model `m`.
"""
function add_variable_storages_early_decommissioned_vintage!(m::Model)
    add_variable!(m, :storages_early_decommissioned_vintage, storages_early_decommissioned_vintage_indices; lb=x -> 0, int=storages_invested_int,vintage=true)
end
