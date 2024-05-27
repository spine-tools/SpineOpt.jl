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
    _add_constraint!(m, :unit_lifetime, constraint_unit_lifetime_indices, _build_constraint_unit_lifetime)
end

function _build_constraint_unit_lifetime(m::Model, u, s_path, t)
    @fetch units_invested_available, units_invested = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            units_invested_available[u, s, t]
            for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s_path, t=t);
            init=0,
        )
        >=
        sum(
            units_invested[u, s_past, t_past] * weight
            for (u, s_past, t_past, weight) in _past_units_invested_available_indices(m, u, s_path, t)
        )
    )
end

function constraint_unit_lifetime_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=t)
        for (u, t) in unit_investment_time_indices(m; unit=indices(unit_investment_lifetime))
        for path in active_stochastic_paths(m, _past_units_invested_available_indices(m, u, anything, t))
    )
end

function _past_units_invested_available_indices(m, u, s_path, t)
    _past_indices(m, units_invested_available_indices, unit_investment_lifetime, s_path, t; unit=u)
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