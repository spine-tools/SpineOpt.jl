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
    add_constraint_mp_unit_lifetime!(m::Model)

Constrain units_invested_available by the investment lifetime of a unit.
"""

function add_constraint_mp_unit_lifetime!(m::Model)
    @fetch mp_units_invested_available, mp_units_invested = m.ext[:variables]
    cons = m.ext[:constraints][:mp_unit_lifetime] = Dict()
    for (u, stochastic_path, t) in constraint_mp_unit_lifetime_indices()        
        cons[u, stochastic_path, t] = @constraint(
            m,
            + expr_sum(
                + mp_units_invested_available[u, s, t]
                for (u, s, t) in mp_units_invested_available_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
            >=
            + sum(
                + mp_units_invested[u, s_past, t_past]
                for (u, s_past, t_past) in mp_units_invested_available_indices(
                    unit=u,
                    stochastic_scenario=stochastic_path,
                    t=to_mp_time_slice(TimeSlice(end_(t) - unit_investment_lifetime(unit=u), end_(t)))
                )
            )
        )
    end
end


"""
    constraint_unit_lifetime_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of the `units_invested_available` variable on past time slices determined
by the `unit_investment_lifetime` parameter.
"""


function constraint_mp_unit_lifetime_indices()
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        for t in time_slice(temporal_block=unit__investment_temporal_block(unit=u))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in mp_units_invested_available_indices(
                    unit=u, t=vcat(to_time_slice(TimeSlice(end_(t) - unit_investment_lifetime(unit=u), end_(t))), t),
                )  
            )
        )
    )
end
