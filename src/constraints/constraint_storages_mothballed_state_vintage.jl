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
    add_constraint_storages_mothballed_state_vintage!(m::Model)

Constrain `storages_mothballed_state_vintage` by the storages de-/mothballed during current and previous timesteps.
"""
function add_constraint_storages_mothballed_state_vintage!(m::Model)
    @fetch storages_mothballed_state_vintage, storages_mothballed_vintage, storages_demothballed_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:storages_mothballed_state_vintage] = Dict(
        (node=n, stochastic_path=s, t_vintage=t_v, t=t_after) => @constraint(
            m,
            + expr_sum(
                + storages_mothballed_state_vintage[n, s_after, t_v, t_after]
                - storages_mothballed_state_vintage[n, s_before, t_v, t_before]
                for (n, s_after, t_v, t_after) in storages_invested_available_vintage_indices(m; node=n, stochastic_scenario=s, t_vintage=t_v, t=t_after)
                    for (n, s_before, t_v, t_before) in storages_invested_available_vintage_indices(m; node=n, stochastic_scenario=s, t_vintage=t_v, t=t_before_t(m;t_after=t_after));
                init=0,
            )
            ==
            + expr_sum(
                + storages_mothballed_vintage[n, s, t_v, t_after]
                - storages_demothballed_vintage[n, s, t_v, t_after]
                for (n, s, t_v, t_after) in storages_invested_available_vintage_indices(m; node=n, stochastic_scenario=s, t_vintage=t_v, t=t_after);
                init=0,
            )
        ) for (n, s, t_v, t_after) in constraint_storages_mothballed_state_vintage_indices(m)
    )
end

function constraint_storages_mothballed_state_vintage_indices(m::Model)
    unique(
        (node=n, stochastic_path=path, t_vintage=t_v, t=t)
        for n in node(storages_mothballing=true) for (n, s, t_v, t) in storages_invested_available_vintage_indices(m; node=n)
        for path in active_stochastic_paths(_constraint_storages_mothballed_state_vintage_indices(m, n, s, t))
    )
end

"""
    constraint_storages_mothballed_state_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:storages_mothballed_state_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_storages_mothballed_state_vintage_indices_filtered(m::Model; node=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_storages_mothballed_state_vintage_indices(m))
end

"""
    _constraint_storages_mothballed_state_vintage_indices(m, n, s, t)

Gathers the `stochastic_scenario` indices of the `storages_mothballed_state_vintage` variable on the current and previous time slice.
"""
function _constraint_storages_mothballed_state_vintage_indices(m, n, s, t)
    unique(ind.stochastic_scenario for ind in storages_invested_available_indices(m; node=n, t=[t_before_t(m;t_after=t)...,t]))
end
