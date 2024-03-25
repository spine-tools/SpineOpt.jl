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
This constraint describes the relationship between units_out_of_service, units_taken_out_of_service and units_returned_to_service:

```math
\begin{aligned}
& v^{units\_on}_{(u,s,t)} - v^{units\_taken\_out\_of\_service}_{(u,s,t)} + v^{units\_returned\_to\_service}_{(u,s,t)} = v^{units\_out\_of\_service}_{(u,s,t-1)} \\
& \forall u \in unit \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_units_out_of_service_transition!(m::Model)
    @fetch units_out_of_service, units_returned_to_service, units_taken_out_of_service = m.ext[:spineopt].variables
    
    m.ext[:spineopt].constraints[:units_out_of_service_transition] = Dict(
        (unit=u, stochastic_path=s_path, t_before=t_before, t_after=t_after) => @constraint(
            m,
            sum(
                + units_out_of_service[u, s, t_after]
                - units_taken_out_of_service[u, s, t_after]
                + units_returned_to_service[u, s, t_after]
                for (u, s, t_after) in units_on_indices(
                    m; unit=u, stochastic_scenario=s_path, t=t_after, temporal_block=anything,
                );
                init=0,
            )
            ==
            sum(
                units_out_of_service[u, s, t_before]
                for (u, s, t_before) in units_on_indices(
                    m; unit=u, stochastic_scenario=s_path, t=t_before, temporal_block=anything,
                );
                init=0,
            )
        )
        for (u, s_path, t_before, t_after) in constraint_units_out_of_service_transition_indices(m)
    )
end

function constraint_units_out_of_service_transition_indices(m::Model)
    unique(
        (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, t_before, t_after) in unit_dynamic_time_indices(m)
        for path in active_stochastic_paths(
            m, units_on_indices(m; unit=u, t=[t_before, t_after], temporal_block=anything)
        )
    )
end