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
`units_available` variables.
"""
function constraint_min_up_time_indices()
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(min_up_time)
        for t in time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=u)))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in units_on_indices(
                    unit=u, t=vcat(to_time_slice(TimeSlice(end_(t) - min_up_time(unit=u), end_(t))), t),
                )  # Current `units_on` and `units_available`, plus `units_started_up` during past time slices
            )
        )
    )
end

"""
    add_constraint_min_up_time!(m::Model)

Constrain running by minimum up time.
"""

function add_constraint_min_up_time!(m::Model)
    @fetch units_on, units_started_up= m.ext[:variables] #, nonspin_shutting_down
    m.ext[:constraints][:min_up_time] = Dict(
        (u, stochastic_path, t) => @constraint(
            m,
            + expr_sum(
                + units_on[u, s, t]
                for (u, s, t) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
            >=
            # TODO:
            # + expr_sum(
            #     + nonspin_shutting_down[u, n, s, t]
            #     for (u, n, s, t) in nonspin_shutting_down_indices(
            #         unit=u,
            #         stochastic_scenario=stochastic_path,
            #         t=t_before_t(t_after=t_before_t(t_after=t))
            #         );
            #         init=0
            # )
            + sum(
                + units_started_up[u, s_past, t_past]
                for (u, s_past, t_past) in units_on_indices(
                    unit=u,
                    stochastic_scenario=stochastic_path,
                    t=to_time_slice(TimeSlice(end_(t) - min_up_time(unit=u), end_(t)))
                )
            )
        )
        for (u, stochastic_path, t) in constraint_min_up_time_indices()
    )
end
