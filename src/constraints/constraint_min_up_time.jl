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
Similarly to the [minimum down time constraint](@ref constraint_min_down_time),
a minimum time that a unit needs to remain online after a start up can be imposed
by defining the [min\_up\_time](@ref) parameter. This will trigger the generation of the following constraint:

```math
\begin{aligned}
& v^{units\_on}_{(u,s,t)} - \sum_{n} v^{nonspin\_units\_shut\_down}_{(u,n,s,t)} \\
& \geq
\sum_{t'=t-p^{min\_up\_time}_{(u,s,t)} +1 }^{t}
v^{units\_started\_up}_{(u,s,t')} \\
& \forall u \in indices(p^{min\_up\_time})\\
& \forall (s,t)
\end{aligned}
```

See also
[min\_up\_time](@ref)
"""
function add_constraint_min_up_time!(m::Model)
    @fetch units_on, units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:min_up_time] = Dict(
        (unit=u, stochastic_path=s_path, t=t) => @constraint(
            m,
            + sum(
                + units_on[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t, temporal_block=anything);
                init=0,
            )
            - sum(
                + nonspin_units_shut_down[u, n, s, t]
                for (u, n, s, t) in nonspin_units_shut_down_indices(
                    m; unit=u, stochastic_scenario=s_path, t=t, temporal_block=anything,
                );
                init=0,
            )
            >=
            + sum(
                units_started_up[u, s_past, t_past]
                for (u, s_past, t_past) in past_units_on_indices(m, u, s_path, t, min_up_time)
            )
        )
        for (u, s_path, t) in constraint_min_up_time_indices(m)
    )
end

function constraint_min_up_time_indices(m::Model; unit=anything, stochastic_path=anything, t=anything)
    (
        (unit=u, stochastic_path=path, t=t)
        for u in indices(min_up_time)
        for (u, t) in unit_time_indices(m; unit=u)
        for path in active_stochastic_paths(m, past_units_on_indices(m, u, anything, t, min_up_time))
    )
end

"""
    constraint_min_up_time_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:min_up_time` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `units_on` and
`units_started_up` variables on past time slices. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_min_up_time_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_up_time_indices(m))
end
