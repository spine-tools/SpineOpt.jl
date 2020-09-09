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
    constraint_min_up_time_indices()

Form the stochastic index set for the `:min_up_time` constraint.
    
Uses stochastic path indices due to potentially different stochastic structures between `units_on` and
`units_started_up` variables on past time slices.
"""
function constraint_min_up_time_indices(m)
    t0 = startref(current_window(m))
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(min_up_time)
        for t in time_slice(m; temporal_block=units_on__temporal_block(unit=u))
        for (u, s, t) in units_on_indices(m; unit=u, t=t)
        for path in active_stochastic_paths(_constraint_min_up_time_indices(m, u, s, t0, t))
    )
end

"""
    _constraint_min_up_time_indices(m, u, s, t0, t)

Gather the `stochastic_scenario` indices of the `units_started_up` variable on past time slices.
"""
function _constraint_min_up_time_indices(m, u, s, t0, t)
    t_past_and_present = to_time_slice(
        m; 
        t=TimeSlice(end_(t) - min_up_time(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t))
    )
    unique(ind.stochastic_scenario for ind in units_on_indices(m; unit=u, t=t_past_and_present))
end

"""
    add_constraint_min_up_time!(m::Model)

Constrain running by minimum up time.
"""

function add_constraint_min_up_time!(m::Model)
    @fetch units_on, units_started_up= m.ext[:variables] #, nonspin_shutting_down
    t0 = startref(current_window(m))
    m.ext[:constraints][:min_up_time] = Dict(
        (u, s, t) => @constraint(
            m,
            + expr_sum(
                + units_on[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0
            )
            >=
            + sum(
                + units_started_up[u, s_past, t_past]
                for (u, s_past, t_past) in units_on_indices(
                    m; 
                    unit=u,
                    stochastic_scenario=s,
                    t=to_time_slice(
                        m; 
                        t=TimeSlice(
                            end_(t) - min_up_time(unit=u, stochastic_scenario=s, analysis_time=t0, t=t), end_(t)
                        )
                    )
                )
            )
        )
        for (u, s, t) in constraint_min_up_time_indices(m)
    )
end
