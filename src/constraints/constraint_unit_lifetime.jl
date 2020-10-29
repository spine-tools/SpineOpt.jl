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
<<<<<<< HEAD
    constraint_unit_lifetime_indices()

Form the stochastic index set for the `:units_invested_lifetime()` constraint. 
"""
function constraint_unit_lifetime_indices(m)
    t0 = startref(current_window(m))
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        for t in time_slice(m; temporal_block=unit__investment_temporal_block(unit=u))
        for (u, s, t) in units_invested_available_indices(m; unit=u, t=t)
        for path in active_stochastic_paths(_constraint_unit_lifetime_indices(m, u, s, t0, t))
    )
end


"""
    _constraint_unit_lifetime_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of the `units_invested_available` variable on past time slices determined
by the `unit_investment_lifetime` parameter.
"""
function _constraint_unit_lifetime_indices(m, u, s, t0, t)
    t_past_and_present = to_time_slice(
        m; 
        t=TimeSlice(end_(t) - unit_investment_lifetime(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t))
    )
    unique(
        ind.stochastic_scenario
        for ind in units_invested_available_indices(m; unit=u, t=t_past_and_present)
    )
end


function constraint_mp_unit_lifetime_indices()
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        for t in mp_time_slice(temporal_block=unit__investment_temporal_block(unit=u))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in mp_units_invested_available_indices(
                    unit=u, t=vcat(to_mp_time_slice(TimeSlice(end_(t) - unit_investment_lifetime(unit=u), end_(t))), t),
                )  
            )
        )
    )
end


"""
=======
>>>>>>> 11d1a5d4bb5841ef349d93e2ba389b0f2df7d46a
    add_constraint_unit_lifetime!(m::Model)

Constrain units_invested_available by the investment lifetime of a unit.
"""
function add_constraint_unit_lifetime!(m::Model)
    @fetch units_invested_available, units_invested = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:unit_lifetime] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + units_invested_available[u, s, t]
                for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0
            )
            >=
            + sum(
                + units_invested[u, s_past, t_past]
                for (u, s_past, t_past) in units_invested_available_indices(
                    m;
                    unit=u,
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m;
                        t=TimeSlice(
                            end_(t) - unit_investment_lifetime(unit=u, stochastic_scenario=s, analysis_time=t0, t=t),
                            end_(t)
                        )
                    )
                )
            )
        )
        for (u, s, t) in constraint_unit_lifetime_indices(m)
    )
end

<<<<<<< HEAD

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
=======
"""
    constraint_unit_lifetime_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_lifetime()` constraint. 

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_unit_lifetime_indices(m::Model; unit=anything, stochastic_path=anything, t=anything)
    t0 = startref(current_window(m))
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(unit_investment_lifetime)
        if u in unit
        for t in time_slice(m; temporal_block=unit__investment_temporal_block(unit=u), t=t)
        for (u, s, t) in units_invested_available_indices(m; unit=u, t=t)
        for path in active_stochastic_paths(_constraint_unit_lifetime_indices(m, u, s, t0, t))
        if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_unit_lifetime_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of the `units_invested_available` variable on past time slices determined
by the `unit_investment_lifetime` parameter.
"""
function _constraint_unit_lifetime_indices(m, u, s, t0, t)
    t_past_and_present = to_time_slice(
        m; 
        t=TimeSlice(end_(t) - unit_investment_lifetime(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t))
    )
    unique(
        ind.stochastic_scenario
        for ind in units_invested_available_indices(m; unit=u, t=t_past_and_present)
    )
>>>>>>> 11d1a5d4bb5841ef349d93e2ba389b0f2df7d46a
end