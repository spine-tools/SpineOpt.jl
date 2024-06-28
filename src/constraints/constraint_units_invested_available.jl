#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

@doc raw"""
The number of available invested-in units at any point in time is less than the number of investment candidate units.

```math
\begin{aligned}
& v^{units\_invested\_available}_{(u,s,t)} < p^{candidate\_units}_{(u)} \\
& \forall u \in unit: p^{candidate\_units}_{(u)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_units_invested_available!(m::Model)
    _add_constraint!(
        m, :units_invested_available, units_invested_available_indices, _build_constraint_units_invested_available
    )
end

function _build_constraint_units_invested_available(m::Model, u, s, t)
    @fetch units_invested_available = m.ext[:spineopt].variables
    @build_constraint(units_invested_available[u, s, t] <= candidate_units(m; unit=u, stochastic_scenario=s, t=t))
end
