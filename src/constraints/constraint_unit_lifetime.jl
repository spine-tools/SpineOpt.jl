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
    add_constraint_unit_lifetime!(m::Model)

Constrain units_invested_available by the investment lifetime of a unit.
"""
function add_constraint_unit_lifetime!(m::Model)
    @fetch units_invested_available, units_invested = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:unit_lifetime] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + units_invested_available[u, s, t]
                for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            + sum(
                + units_invested[u, s_past, t_past] for (u, s_past, t_past) in units_invested_available_indices(
                    m;
                    unit=u,
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m;
                        t=TimeSlice(
                            end_(t) - unit_investment_lifetime(unit=u, stochastic_scenario=s, analysis_time=t0, t=t),
                            end_(t),
                        ),
                    ),
                )
            )
        ) for (u, s, t) in constraint_unit_lifetime_indices(m)
    )
end

function constraint_unit_lifetime_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime) for (u, s, t) in units_invested_available_indices(m; unit=u)
        for path in active_stochastic_paths(_constraint_unit_lifetime_indices(m, u, s, t0, t))
    )
end

"""
    constraint_unit_lifetime_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_lifetime()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_unit_lifetime_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_lifetime_indices(m))
end

"""
    _constraint_unit_lifetime_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of the `units_invested_available` variable on past time slices determined
by the `unit_investment_lifetime` parameter.
"""
function _constraint_unit_lifetime_indices(m, u, s, t0, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(end_(t) - unit_investment_lifetime(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t)),
    )
    unique(ind.stochastic_scenario for ind in units_invested_available_indices(m; unit=u, t=t_past_and_present))
end
