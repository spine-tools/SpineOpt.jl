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
    add_constraint_storage_lifetime!(m::Model)

Constrain storages_invested_available by the investment lifetime of a storage.
"""
function add_constraint_storage_lifetime!(m::Model)
    _add_constraint!(m, :storage_lifetime, constraint_storage_lifetime_indices, _build_constraint_storage_lifetime)
end

function _build_constraint_storage_lifetime(m::Model, n, s_path, t)
    @fetch storages_invested_available, storages_invested = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            storages_invested_available[n, s, t]
            for (n, s, t) in storages_invested_available_indices(m; node=n, stochastic_scenario=s_path, t=t);
            init=0,
        )
        >=
        sum(
            storages_invested[n, s_past, t_past]
            for (n, s_past, t_past) in _past_storages_invested_available_indices(m, n, s_path, t)
        )
    )
end

function constraint_storage_lifetime_indices(m::Model)
    (
        (node=n, stochastic_path=path, t=t)
        for (n, t) in node_investment_time_indices(m; node=indices(storage_investment_lifetime))
        for path in active_stochastic_paths(m, _past_storages_invested_available_indices(m, n, anything, t))
    )
end

function _past_storages_invested_available_indices(m, n, s_path, t)
    storages_invested_available_indices(
        m;
        node=n,
        stochastic_scenario=s_path,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - storage_investment_lifetime(node=n, stochastic_scenario=s_path, t=t), end_(t))
        )
    )
end

"""
    constraint_storage_lifetime_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:storages_invested_lifetime()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_storage_lifetime_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_storage_lifetime_indices(m))
end