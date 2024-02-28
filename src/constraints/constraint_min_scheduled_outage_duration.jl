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
The number of online units needs to be restricted to the aggregated available units:

```math
v^{units\_on}_{(u,s,t)} \leq v^{units\_available}_{(u,s,t)} \quad \forall u \in unit, \, \forall (s,t)
```

The investment formulation is described in chapter [Investments](@ref).
"""
function add_constraint_min_scheduled_outage_duration!(m::Model)
    @fetch units_out_of_service = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:min_scheduled_outage_duration] = Dict(
        (unit=u, stochastic_scenario=s_long, t=t_long) => @constraint(
            m, 
            + sum(
                units_out_of_service[u, s, t] * duration(t)
                for (u, s, t) in units_on_indices(m; unit=u);
                init=0
            ) 
            >= ( + scheduled_outage_duration[(unit=u, stochastic_scenario=s_long, analysis_time=t0, t=t_long)]
               * number_of_units[(unit=u, stochastic_scenario=s_long, analysis_time=t0, t=t_long)])
               / _model_duration_unit(m.ext[:spineopt].instance)(1)
            
        )
        for (u, s_long, t_long) in constraint_min_scheduled_outage_duration_indices(m)
    )
end

"""
    constraint_scheduled_outage_duration_indices(m::Model, unit, t)
    
Creates all indices required to include units, stochastic paths and a reference temporal for `add_constraint_scheduled_outage_duration!`
constraint generation.
"""
function constraint_min_scheduled_outage_duration_indices(m::Model)
    unique(
        (unit=u, stochastic_scenario=s, t=t)
        for u in indices(scheduled_outage_duration)
        for t in current_window(m)
        for path in active_stochastic_paths(
            m, [units_on_indices(m; unit=u); ]
        )
        for s in path
    )
end
