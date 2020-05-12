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
    constraint_min_up_time_indices()

Forms the stochastic index set for the `:min_up_time` constraint. Uses stochastic path
indices due to potentially different stochastic structures between `units_on` and
`units_available` variables.
"""
function constraint_min_up_time_indices()
    min_up_time_indices = []
    for u in indices(min_up_time)
        node = first(units_on_resolution(unit=u))
        tb = node__temporal_block(node=node)
        for t in time_slice(temporal_block=tb)
            # Current `units_on`
            active_scenarios = units_on_indices_rc(unit=u, t=t, _compact=true)
            # `units_started_up` during past time slices
            append!(
                active_scenarios,
                units_on_indices_rc(
                    unit=u,
                    t=to_time_slice(TimeSlice(end_(t) - min_up_time(unit=u), end_(t))),
                    _compact=true
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    min_up_time_indices,
                    (unit=u, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(min_up_time_indices)
end


"""
    add_constraint_min_up_time!(m::Model)

Constraint running by minimum up time.
"""

function add_constraint_min_up_time!(m::Model)
    @fetch units_on, units_started_up = m.ext[:variables]
    cons = m.ext[:constraints][:min_up_time] = Dict()
    for (u, stochastic_path, t) in constraint_min_up_time_indices()
        cons[u, stochastic_path, t] = @constraint(
            m,
            + expr_sum(
                + units_on[u, s, t]
                for (u, s, t) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
            >=
            + sum(
                + units_started_up[u, s_past, t_past]
                for (u, s_past, t_past) in units_on_indices(
                    unit=u,
                    stochastic_scenario=stochastic_path,
                    t=to_time_slice(TimeSlice(end_(t) - min_up_time(unit=u), end_(t)))
                )
            )
        )
    end
end