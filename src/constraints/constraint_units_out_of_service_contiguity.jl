#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    _add_constraint!(
        m,
        :units_out_of_service_contiguity,
        constraint_units_out_of_service_contiguity_indices,
        _build_constraint_units_out_of_service_contiguity,
    )
end

function _build_constraint_units_out_of_service_contiguity(m::Model, u, s_path, t)
    @fetch units_out_of_service, units_taken_out_of_service, units_returned_to_service = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + units_out_of_service[u, s, t]
            for (u, s, t) in units_out_of_service_indices(
                m; unit=u, stochastic_scenario=s_path, t=t, temporal_block=anything
            );
            init=0,
        )
        >=
        + sum(
            units_taken_out_of_service[u, s_past, t_past] * weight
            for (u, s_past, t_past, weight) in past_units_out_of_service_indices(m, u, s_path, t)
        )
    )
end

function past_units_out_of_service_indices(m, u, s_path, t)
    _past_indices(m, units_out_of_service_indices, scheduled_outage_duration, s_path, t; unit=u)
end

function constraint_units_out_of_service_contiguity_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=t)
        for u in indices(scheduled_outage_duration)
        for (u, t) in unit_time_indices(m; unit=u)
        for path in active_stochastic_paths(m, past_units_out_of_service_indices(m, u, anything, t))
    )
end