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
The aggregated available units are constrained by the parameter [number\_of\_units](@ref)
, the variable number of invested units [units\_invested\_available](@ref) less the number of units on outage [units\_out\_of\_service](@ref):

```math
\begin{aligned}
& v^{units\_available}_{(u,s,t)} \leq p^{number\_of\_units}_{(u,s,t)} + v^{units\_invested\_available}_{(u,s,t)} + v^{units\_out\_of\_service}_{(u,s,t)}\\
& \forall u \in unit \\
& \forall (s,t)
\end{aligned}
```

See also [number\_of\_units](@ref).
"""
function add_constraint_units_available!(m::Model)
    @fetch units_on, units_out_of_service, units_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:units_available] = Dict(
        (unit=u, stochastic_scenario=s, t=t) => @constraint(
            m,
            + sum(
                + units_on[u, s, t] 
                + units_out_of_service[u, s, t]
                for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            - sum(
                units_invested_available[u, s, t1]
                for (u, s, t1) in units_invested_available_indices(
                    m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t)
                );
                init=0,
            )            
            <=
            number_of_units(m; unit=u, stochastic_scenario=s, analysis_time=t0, t=t)
        )
        for (u, s, t) in constraint_units_available_indices(m)
    )
end

"""
    constraint_units_available_indices(m::Model, unit, t)
    
Creates all indices required to include units, stochastic paths and temporals for the `add_constraint_units_available!`
constraint generation.
"""
function constraint_units_available_indices(m::Model)
    (
        (unit=u, stochastic_scenario=s, t=t)
        for (u, t) in unit_time_indices(m)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (units_on_indices(m; unit=u, t=t), units_invested_available_indices(m; unit=u, t=t_overlaps_t(m; t=t)))
            ),
        )
        for s in path
    )
end
