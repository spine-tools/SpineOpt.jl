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
    add_constraint_storages_invested_state_vintage!(m::Model)

Constrain storages_invested_state_vintage by the investment lifetime of a storage and early decomissioning.
"""
function add_constraint_storages_invested_state_vintage!(m::Model)
    @fetch storages_invested_state_vintage, storages_invested, storages_early_decommissioned_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:storages_invested_state_vintage] = Dict(
        (node=n, stochastic_path=s, t_vintage=t_v, t=t) => @constraint(
            m,
            + expr_sum(
                + storages_invested_state_vintage[n, s, t_v, t]
                for (n, s, t_v, t) in storages_invested_available_vintage_indices(m; node=n, stochastic_scenario=s, t_vintage=t_v, t=t);
                init=0,
            )
            ==
            #FIXME: can we fix this parameter call? Currently, first needs to be added
            + expr_sum(
                    + storage_capacity_transfer_factor[(node=n, stochastic_scenario=s_v,vintage_t=first(t_v.start),t=t)]
                    * (storages_invested[n, s_v, t_v]
                    - expr_sum(
                        storages_early_decommissioned_vintage[n, s_, t_v, t_]
                        for (n, s_, t_v, t_) in storages_early_decommissioned_vintage_indices(
                            m;
                            node=n,
                            stochastic_scenario=s,
                            t=to_time_slice(
                                m;
                                t=TimeSlice(
                                    start(t_v),
                                    end_(t),
                                ),
                            ),
                        );
                    init=0
                    )
                )
                for (n, s_v, t_v) in storages_invested_available_indices(
                            m;
                            node=n,
                            stochastic_scenario=s,
                            t=t_v,
                            )
                ; init=0
                )
        ) for (n, s, t_v, t) in constraint_storages_invested_state_vintage_indices(m)
    )
end

function constraint_storages_invested_state_vintage_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (node=n, stochastic_path=path, t_vintage=t_v, t=t)
        for n in indices(storage_investment_tech_lifetime) for (n, s, t_v, t) in storages_invested_available_vintage_indices(m; node=n)
        for path in active_stochastic_paths(_constraint_storages_invested_state_vintage_indices(m, n, s, t_v, t))
    )
end

"""
    constraint_storages_invested_state_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:storages_invested_state_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_storages_invested_state_vintage_indices_filtered(m::Model; node=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_storages_invested_state_vintage_indices(m))
end

"""
    _constraint_storage_lifetime_indices(n, s, t0, t)

Gathers the `stochastic_scenario` indices of the `storages_invested_available` variable on past time slices determined
by the `storage_investment_tech_lifetime` parameter.
"""
function _constraint_storages_invested_state_vintage_indices(m, n, s, t_v, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(start(t_v), end_(t)),
    )
    unique(ind.stochastic_scenario for ind in storages_invested_available_indices(m; node=n, t=t_past_and_present))
end
