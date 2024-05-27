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
The unit must be taken out of service for maintenance for a duration equal to scheduled_outage_duration:

```math
\sum_{t} v^{units\_out\_of\_service}_{(u,s,t)}duration_t
\geq scheduled\_outage\_duration_{(u,s,t)}number\_of\_units_u \quad \forall u \in unit, \, \forall (s,t)
```

"""
function add_constraint_min_scheduled_outage_duration!(m::Model)
    _add_constraint!(
        m,
        :min_scheduled_outage_duration,
        constraint_min_scheduled_outage_duration_indices,
        _build_constraint_min_scheduled_outage_duration,
    )
end

function _build_constraint_min_scheduled_outage_duration(m::Model, u, s_path, t)
    @fetch units_out_of_service = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + units_out_of_service[u, s, t] * duration(t)
            for (u, s, t) in units_out_of_service_indices(m; unit=u, stochastic_scenario=s_path);
            init=0,
        )
        ==
        + maximum(
            (
                + scheduled_outage_duration(m; unit=u, stochastic_scenario=s, t=t)
                * number_of_units(m; unit=u, stochastic_scenario=s, t=t)
            ) / _model_duration_unit(m.ext[:spineopt].instance)(1)
            for s in s_path;
            init=0,
        )
    )
end

"""
    constraint_scheduled_outage_duration_indices(m::Model, unit, t)
    
Creates all indices required to include units, stochastic paths and a reference temporal for `add_constraint_scheduled_outage_duration!`
constraint generation.
"""
function constraint_min_scheduled_outage_duration_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=current_window(m))
        for u in indices(scheduled_outage_duration)
        for path in active_stochastic_paths(m, units_out_of_service_indices(m; unit=u))        
    )
end
