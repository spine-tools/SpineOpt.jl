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
    constraint_units_invested_lifetime_indices()

Forms the stochastic index set for the `:units_invested_lifetime()` constraint. 
"""

function constraint_unit_lifetime_indices()
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        for t in time_slice(temporal_block=unit__investment_temporal_block(unit=u))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in units_invested_available_indices(
                    unit=u, t=vcat(to_time_slice(TimeSlice(end_(t) - unit_investment_lifetime(unit=u), end_(t))), t),
                )  
            )
        )
    )
end


"""
    add_constraint_min_up_time!(m::Model)

Constraint running by minimum up time.
"""

function add_constraint_unit_lifetime!(m::Model)
    @fetch units_invested_available, units_invested = m.ext[:variables]
    cons = m.ext[:constraints][:unit_lifetime] = Dict()
    for (u, stochastic_path, t) in constraint_unit_lifetime_indices()        
        cons[u, stochastic_path, t] = @constraint(
            m,
            + expr_sum(
                + units_invested_available[u, s, t]
                for (u, s, t) in units_invested_available_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
            >=
            + sum(
                + units_invested[u, s_past, t_past]
                for (u, s_past, t_past) in units_invested_available_indices(
                    unit=u,
                    stochastic_scenario=stochastic_path,
                    t=to_time_slice(TimeSlice(end_(t) - unit_investment_lifetime(unit=u), end_(t)))
                )
            )
        )
    end
end