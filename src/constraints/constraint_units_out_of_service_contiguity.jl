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
Enforces that maintenance outages are taken as a contiguous block. 
By defining the [scheduled\_outage\_duration](@ref) parameter. This will trigger the generation of the following constraint:

```math
\begin{aligned}
& v^{units\_out\_of\_service}_{(u,s,t)} - \sum_{n} v^{units\_returned\_to\_service}_{(u,n,s,t)} \\
& \geq
\sum_{t'=t-p^{schuled\_outage\_duration}_{(u,s,t)} +1 }^{t}
v^{units\_taken\_out\_of\_service}_{(u,s,t')} \\
& \forall u \in indices(p^{scheduled\_outage\_duration})\\
& \forall (s,t)
\end{aligned}
```

See also
[scheduled\_outage\_duration](@ref)
"""
function add_constraint_units_out_of_service_contiguity!(m::Model)
    @fetch units_out_of_service, units_taken_out_of_service, units_returned_to_service = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:units_out_of_service_contiguity] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            + expr_sum(
                + units_out_of_service[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t, temporal_block=anything);
                init=0,
            )
            - expr_sum(
                + units_returned_to_service[u, s, t]
                for (u, s, t) in units_on_indices(
                    m; unit=u, stochastic_scenario=s, t=t, temporal_block=anything,
                );
                init=0,
            )
            >=
            + sum(
                units_taken_out_of_service[u, s_past, t_past]
                for (u, s_past, t_past) in past_units_out_of_service_indices(m, u, s, t, scheduled_outage_duration)
            )
        )
        for (u, s, t) in constraint_units_out_of_service_contiguity_indices(m)
    )
end

function constraint_units_out_of_service_contiguity_indices(m::Model; unit=anything, stochastic_path=anything, t=anything)
    unique(
        (unit=u, stochastic_path=path, t=t)
        for u in indices(scheduled_outage_duration)
        for (u, t) in unit_time_indices(m; unit=u)
        for path in active_stochastic_paths(m, past_units_out_of_service_indices(m, u, anything, t, scheduled_outage_duration))
    )
end

"""
    constraint_units_out_of_service_contiguity_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_out_of_service_contiguity` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `units_out_of_service` and
`units_taken_out_of_service` variables on past time slices. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_units_out_of_service_contiguity_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_units_out_of_service_contiguity_indices(m))
end

function past_units_out_of_service_indices(m, u, s, t, min_time)
    t0 = _analysis_time(m)
    units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - min_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t))
        ),
        temporal_block=anything
    )    
end