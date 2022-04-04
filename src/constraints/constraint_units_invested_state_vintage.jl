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
    add_constraint_units_invested_state_vintage!(m::Model)

Constrain units_invested_state_vintage by the investment lifetime of a unit and early decomissioning.
"""
function add_constraint_units_invested_state_vintage!(m::Model)
    @fetch units_invested_state_vintage, units_invested, units_early_decommissioned_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_invested_state_vintage] = Dict(
        (unit=u, stochastic_path=s, t_vintage=t_v, t=t) => @constraint(
            m,
            + expr_sum(
                + units_invested_state_vintage[u, s, t_v, t]
                for (u, s, t_v, t) in units_invested_available_vintage_indices(m; unit=u, stochastic_scenario=s, t_vintage=t_v, t=t);
                init=0,
            )
            ==
            #FIXME: can we fix this parameter call? Currently, first needs to be added
            + expr_sum(
                    + unit_capacity_transfer_factor[(unit=u, stochastic_scenario=s_v,vintage_t=first(t_v.start),t=t)]
                    * (units_invested[u, s_v, t_v]
                    - expr_sum(
                        units_early_decommissioned_vintage[u, s_, t_v, t_]
                        for (u, s_, t_v, t_) in units_early_decommissioned_vintage_indices(
                            m;
                            unit=u,
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
                for (u, s_v, t_v) in units_invested_available_indices(
                            m;
                            unit=u,
                            stochastic_scenario=s,
                            t=t_v,
                            )
                ; init=0
                )
        ) for (u, s, t_v, t) in constraint_units_invested_state_vintage_indices(m)
    )
end

function constraint_units_invested_state_vintage_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (unit=u, stochastic_path=path, t_vintage=t_v, t=t)
        for (u, s, t_v, t) in units_invested_available_vintage_indices(m)
        for path in active_stochastic_paths(_constraint_units_invested_state_vintage_indices(m, u, s, t_v, t))
    )
end

"""
    constraint_units_invested_state_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_state_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_units_invested_state_vintage_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_units_invested_state_vintage_indices(m))
end

"""
    _constraint_unit_lifetime_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of the `units_invested_available` variable on past time slices determined
by the `unit_investment_tech_lifetime` parameter.
"""
function _constraint_units_invested_state_vintage_indices(m, u, s, t_v, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(start(t_v), end_(t)),
    )
    unique(ind.stochastic_scenario for ind in units_invested_available_indices(m; unit=u, t=t_past_and_present))
end
