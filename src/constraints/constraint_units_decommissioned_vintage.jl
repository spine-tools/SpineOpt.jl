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
    add_constraint_units_decommissioned_vintage!(m::Model)

Constrain units_decommissioned_vintage by the difference in available invested units.
"""
function add_constraint_units_decommissioned_vintage!(m::Model)
    @fetch units_decommissioned_vintage, units_invested_state_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_decommissioned_vintage] = Dict(
        (unit=u, stochastic_path=s, t_vintage=t_v, t=t_after) => @constraint(
            m,
            expr_sum(
                + units_decommissioned_vintage[u, s_after, t_v, t_after]
                for (u, s_after, t_v, t_after) in units_invested_available_vintage_indices(m; unit=u, stochastic_scenario=s, t_vintage=t_v, t=t_after);
                init=0
            )
            >=
            + expr_sum(
                + units_invested_state_vintage[u, s_before, t_v, t_before]
                - units_invested_state_vintage[u, s_after, t_v, t_after]
                for (u, s_after, t_v, t_after) in units_invested_available_vintage_indices(m; unit=u, stochastic_scenario=s, t_vintage=t_v, t=t_after)
                    for (u, s_before, t_v, t_before) in units_invested_available_vintage_indices(m; unit=u, stochastic_scenario=s, t_vintage=t_v, t=t_before_t(m;t_after=t_after))
                ;init=0,
            )
        ) for (u, s, t_v, t_after) in constraint_units_decommissioned_vintage_indices(m)
    )
end

function constraint_units_decommissioned_vintage_indices(m::Model)
    unique(
        (unit=u, stochastic_path=path, t_vintage=t_v, t=t)
        for (u, s, t_v, t) in units_invested_available_vintage_indices(m)
        for path in active_stochastic_paths(_constraint_units_decommissioned_vintage_indices(m, u, s, t))
    )
end

"""
    constraint_units_decommissioned_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_decommissioned_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_units_decommissioned_vintage_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_units_decommissioned_vintage_indices(m))
end

"""
    _constraint_units_decommissioned_vintage_indices(m, u, s, t)

Gathers the `stochastic_scenario` indices of the `units_mothballed_state_vintage` variable on the current and previous time slice.
"""
function _constraint_units_decommissioned_vintage_indices(m, u, s, t)
    unique(ind.stochastic_scenario for ind in units_invested_available_indices(m; unit=u, t=[t_before_t(m;t_after=t)...,t]))
end
