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
    add_constraint_units_invested_transition!(m::Model)

Ensure consistency between the variables `units_invested_available`, `units_invested` and `units_mothballed`.
"""
function add_constraint_units_invested_transition!(m::Model)
    @fetch units_invested_available, units_invested, units_mothballed = m.ext[:variables]
    m.ext[:constraints][:units_invested_transition] = Dict(
        (unit=u, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            expr_sum(
                + units_invested_available[u, s, t_after] - units_invested[u, s, t_after]
                + units_mothballed[u, s, t_after]
                for (u, s, t_after) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                init=0,
            )
            ==
            expr_sum(
                + units_invested_available[u, s, t_before]
                for (u, s, t_before) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_before);
                init=0,
            )
        ) for (u, s, t_before, t_after) in constraint_units_invested_transition_indices(m)
    )
end

function constraint_units_invested_transition_indices(m::Model)
    unique(
        (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, t_before, t_after) in unit_investment_dynamic_time_indices(m) for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario for ind in units_invested_available_indices(m; unit=u, t=[t_before, t_after])
            ),
        )
    )
end

"""
    constraint_units_invested_transition_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting array.
"""
function constraint_units_invested_transition_indices_filtered(
    m::Model;
    unit=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_units_invested_transition_indices(m))
end
