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
    constraint_units_invested_transition_indices()

Form the stochastic index set for the `:units_invested_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
"""

function constraint_mp_units_invested_transition_indices()        
    unique(
        (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, tb) in unit__investment_temporal_block()
        for t_after in mp_time_slice(temporal_block=tb)
        for t_before in _take_one_t_before_t(t_after)
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in mp_units_invested_available_indices(unit=u, t=[t_before, t_after]))
        )
    )
end


"""
    add_constraint_mp_units_invested_transition!(m::Model)

Ensure consistency between the variables `units_invested_available`, `units_invested` and `units_mothballed`.
"""

function add_constraint_mp_units_invested_transition!(m::Model)
    @fetch mp_units_invested_available, mp_units_invested, mp_units_mothballed = m.ext[:variables]
    cons = m.ext[:constraints][:mp_units_invested_transition] = Dict()
    for (u, stochastic_path, t_before, t_after) in constraint_mp_units_invested_transition_indices()
        cons[u, stochastic_path, t_before, t_after] = @constraint(
            m,
            expr_sum(
                + mp_units_invested_available[u, s, t_after]
                - mp_units_invested[u, s, t_after]
                + mp_units_mothballed[u, s, t_after]
                for (u, s, t_after) in mp_units_invested_available_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_after
                );
                init=0
            )
            ==
            expr_sum(
                + mp_units_invested_available[u, s, t_before]
                for (u, s, t_before) in mp_units_invested_available_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_before
                );
                init=0
            )
        )
    end
end
