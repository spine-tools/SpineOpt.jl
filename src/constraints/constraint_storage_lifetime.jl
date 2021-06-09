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
    add_constraint_storage_lifetime!(m::Model)

Constrain storages_invested_available by the investment lifetime of a storage.
"""
function add_constraint_storage_lifetime!(m::Model)
    @fetch storages_invested_available, storages_invested = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:storage_lifetime] = Dict(
        (node=n, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + storages_invested_available[n, s, t]
                for (n, s, t) in storages_invested_available_indices(m; node=n, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            + sum(
                + storages_invested[n, s_past, t_past] for (n, s_past, t_past) in storages_invested_available_indices(
                    m;
                    node=n,
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m;
                        t=TimeSlice(
                            end_(t) - storage_investment_lifetime(node=n, stochastic_scenario=s, analysis_time=t0, t=t),
                            end_(t),
                        ),
                    ),
                )
            )
        ) for (n, s, t) in constraint_storage_lifetime_indices(m)
    )
end

function constraint_storage_lifetime_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (node=n, stochastic_path=path, t=t)
        for n in indices(storage_investment_lifetime) for (n, s, t) in storages_invested_available_indices(m; node=n)
        for path in active_stochastic_paths(_constraint_storage_lifetime_indices(m, n, s, t0, t))
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

"""
    _constraint_storage_lifetime_indices(n, s, t0, t)

Gathers the `stochastic_scenario` indices of the `storages_invested_available` variable on past time slices determined
by the `storage_investment_lifetime` parameter.
"""
function _constraint_storage_lifetime_indices(m, n, s, t0, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(
            end_(t) - storage_investment_lifetime(node=n, stochastic_scenario=s, analysis_time=t0, t=t),
            end_(t),
        ),
    )
    unique(ind.stochastic_scenario for ind in storages_invested_available_indices(m; node=n, t=t_past_and_present))
end
