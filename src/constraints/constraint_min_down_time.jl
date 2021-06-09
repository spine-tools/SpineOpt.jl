#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    add_constraint_min_down_time!(m::Model)

Constrain start-up by minimum down time.
"""
function add_constraint_min_down_time!(m::Model)
    @fetch units_invested_available, units_on, units_shut_down, nonspin_units_started_up = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:min_down_time] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            +expr_sum(
                +number_of_units[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] 
                + expr_sum(
                    units_invested_available[u, s, t1]
                    for
                    (u, s, t1) in
                    units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_in_t(m; t_short=t));
                    init=0,
                )
                - units_on[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            + expr_sum(
                + units_shut_down[u, s_past, t_past] for (u, s_past, t_past) in units_on_indices(
                    m;
                    unit=u,
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m;
                        t=TimeSlice(
                            end_(t) - min_down_time(unit=u, stochastic_scenario=s, analysis_time=t0, t=t),
                            end_(t),
                        ),
                    ),
                    temporal_block=anything,
                );
                init=0,
            ) + expr_sum(
                + nonspin_units_started_up[u, n, s, t] for (u, n, s, t) in nonspin_units_started_up_indices(
                    m;
                    unit=u,
                    stochastic_scenario=s,
                    t=t,
                    temporal_block=anything,
                );
                init=0,
            )
        ) for (u, s, t) in constraint_min_down_time_indices(m)
    )
end

#TODO: Does this require nonspin_units_started_up_indices() to be added here?
function constraint_min_down_time_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(min_down_time) for (u, s, t) in units_on_indices(m; unit=u)
        for path in active_stochastic_paths(_constraint_min_down_time_indices(m, u, s, t0, t))
    )
end

"""
    constraint_min_down_time_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:min_down_time` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `units_on`,
`units_available`, `units_shut_down`, and `nonspin_units_started_up` variables on past time slices.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_min_down_time_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_down_time_indices(m))
end

"""
    _constraint_min_down_time_indices(u, s, t0, t)

Gathers the `stochastic_scenario` indices of `units_on` and `nonspin_units_started_up` variables on past time slices.
"""
function _constraint_min_down_time_indices(m, u, s, t0, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(end_(t) - min_down_time(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t)),
    )
    unique(
        ind.stochastic_scenario for ind in Iterators.flatten((
            units_on_indices(m; unit=u, t=t_past_and_present, temporal_block=anything),
            nonspin_units_started_up_indices(m; unit=u, t=t_before_t(m; t_after=t), temporal_block=anything),
        ))
    )
end
