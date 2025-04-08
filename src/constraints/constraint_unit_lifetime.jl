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
Constrain [units\_invested\_available](@ref) by the investment lifetime of a unit.
The parameter [unit\_investment\_lifetime\_sense](@ref) defaults to minimum investment
lifetime ([unit\_investment\_lifetime\_sense](@ref) [`>=`](@ref constraint_sense_list)),
but can be changed to allow strict investment lifetime ([unit\_investment\_lifetime\_sense](@ref) [`==`](@ref constraint_sense_list))
or maximum investment lifetime ([unit\_investment\_lifetime\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The unit lifetime is enforced by the following constraint:

```math
\begin{aligned}
& v^{units\_invested\_available}_{(u,s,t)}
- \sum_{
        t\_past = t-p^{unit\_investment\_tech\_lifetime}
}^{t}
v^{units\_invested}_{(u,s,t\_past)} \\
& \begin{cases}
\ge & \text{if } p^{unit\_investment\_lifetime\_sense} = ">=" \\
= & \text{if } p^{unit\_investment\_lifetime\_sense} = "==" \\
\le & \text{if } p^{unit\_investment\_lifetime\_sense} = "<=" \\
\end{cases} \\
& 0 \\
& \forall (u,s,t)
\end{aligned}
```
"""
function add_constraint_unit_lifetime!(m::Model)
    _add_constraint!(m, :unit_lifetime, constraint_unit_lifetime_indices, _build_constraint_unit_lifetime)
end

function _build_constraint_unit_lifetime(m::Model, u, s_path, t)
    @fetch units_invested_available, units_invested = m.ext[:spineopt].variables
    build_sense_constraint(
        sum(
            units_invested_available[u, s, t]
            for (u, s, t) in units_invested_available_indices(m; unit=u, stochastic_scenario=s_path, t=t);
            init=0,
        )
        -
        sum(
            units_invested[u, s_past, t_past] * weight
            for (u, s_past, t_past, weight) in _past_units_invested_available_indices(m, u, s_path, t)
        ),
        eval(unit_investment_lifetime_sense(unit=u)),
        0
    )
end

function constraint_unit_lifetime_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=t)
        for (u, t) in unit_investment_time_indices(m; unit=indices(unit_investment_tech_lifetime))
        for path in active_stochastic_paths(m, _past_units_invested_available_indices(m, u, anything, t))
    )
end

function _past_units_invested_available_indices(m, u, s_path, t)
    _past_indices(m, units_invested_available_indices, unit_investment_tech_lifetime, s_path, t; unit=u)
end

"""
    constraint_unit_lifetime_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:units_invested_lifetime()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_unit_lifetime_indices_filtered(m::Model; unit=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_lifetime_indices(m))
end