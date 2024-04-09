#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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

@doc raw"""
Similarly to the [minimum up time constraint](@ref constraint_min_up_time),
a minimum time that a unit needs to remain offline after a shut down can be imposed
by defining the [min\_down\_time](@ref) parameter. This will trigger the generation of the following constraint:

```math
\begin{aligned}
& p^{number\_of\_units}_{(u,s,t)} + v^{units\_invested\_available}_{(u,s,t)} - v^{units\_on}_{(u,s,t)} \\
& - \sum_{n} v^{nonspin\_units\_started\_up}_{(u,n,s,t)} \\
& \geq
\sum_{t'=t-p^{min\_down\_time}_{(u,s,t)} + 1}^{t}
v^{units\_shut\_down}_{(u,s,t')} \\
& \forall u \in indices(p^{min\_down\_time})\\
& \forall (s,t)
\end{aligned}
```

See also [number\_of\_units](@ref), [min\_down\_time](@ref).
"""
function add_constraint_min_down_time!(m::Model)
    @fetch units_invested_available, units_on, units_shut_down, nonspin_units_started_up = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:min_down_time] = Dict(
        (unit=u, stochastic_path=s_path, t=t) => @constraint(
            m,
            + sum(
                + number_of_units[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] 
                + sum(
                    units_invested_available[u, s, t1]
                    for (u, s, t1) in units_invested_available_indices(
                        m; unit=u, stochastic_scenario=s, t=t_in_t(m; t_short=t)
                    );
                    init=0,
                )
                - units_on[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t);
                init=0,
            )
            >=
            + sum(
                units_shut_down[u, s_past, t_past]
                for (u, s_past, t_past) in past_units_on_indices(m, u, s_path, t, min_down_time);
                init=0,
            )
            + sum(
                nonspin_units_started_up[u, n, s, t]
                for (u, n, s, t) in nonspin_units_started_up_indices(
                    m; unit=u, stochastic_scenario=s_path, t=t, temporal_block=anything
                );
                init=0,
            )
        )
        for (u, s_path, t) in constraint_min_down_time_indices(m)
    )
end

# TODO: Does this require nonspin_units_started_up_indices() to be added here?
function constraint_min_down_time_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=t)
        for u in indices(min_down_time)
        for (u, t) in unit_time_indices(m; unit=u)
        for path in active_stochastic_paths(
            m, 
            Iterators.flatten(
                (
                    past_units_on_indices(m, u, anything, t, min_down_time),
                    nonspin_units_started_up_indices(m; unit=u, t=t_before_t(m; t_after=t), temporal_block=anything),
                )
            )
        )
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
