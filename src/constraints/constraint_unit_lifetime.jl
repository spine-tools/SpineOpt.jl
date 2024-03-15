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
    add_constraint_unit_lifetime!(m::Model)

Constrain units_invested_available by the investment lifetime of a unit.
"""
function add_constraint_unit_lifetime!(m::Model)
    @fetch units_invested_available, units_invested = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_lifetime] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            sum(
                units_invested_available[u, s, t]
                for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            sum(
                units_invested[u, s_past, t_past]
                for (u, s_past, t_past) in _past_units_invested_available_indices(m, u, s, t)
            )
        )
        for (u, s, t) in constraint_unit_lifetime_indices(m)
    )
end

function constraint_unit_lifetime_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_technical_lifetime)
        for (u, t) in unit_investment_time_indices(m; unit=u)
        for path in active_stochastic_paths(m, _past_units_invested_available_indices(m, u, anything, t))
    )
end

function _past_units_invested_available_indices(m, u, s, t)
    t0 = _analysis_time(m)
    units_invested_available_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m;
            t=TimeSlice(
                end_(t) - unit_investment_technical_lifetime(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t)
            )
        )
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