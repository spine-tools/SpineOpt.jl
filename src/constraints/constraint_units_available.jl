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
    _add_constraint!(m, :units_available, constraint_units_available_indices, _build_constraint_units_available)
end

function _build_constraint_units_available(m, u, s, t)
    @fetch units_on, units_out_of_service, units_invested_available = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + units_on[u, s, t]
            + ifelse(units_unavailable(m; unit=u, stochastic_scenario=s, t=t) > 0, 0, 1)
            * _get_units_out_of_service(m, u, s, t)
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
        # Change the default `number_of_units` so that it is zero when candidate units are present
        # and otherwise 1.
        + number_of_units(m; unit=u, stochastic_scenario=s, t=t, _default=_default_nb_of_units(u))
        - units_unavailable(m; unit=u, stochastic_scenario=s, t=t)
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
        for (u, t) in unit_time_indices(m; unit=_unit_with_online_variable())
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (units_on_indices(m; unit=u, t=t), units_invested_available_indices(m; unit=u, t=t_overlaps_t(m; t=t)))
            ),
        )
        for s in path
    )
end
