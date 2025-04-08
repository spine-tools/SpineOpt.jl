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
The number of available invested-in storages at node ``n`` at any point in time
is less than the number of investment candidate storages at that node.

```math
\begin{aligned}
& v^{storages\_invested\_available}_{(n,s,t)}
\leq p^{candidate\_storages}_{(n,s,t)} \\
& \forall n \in node: p^{candidate\_storages}_{(n)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_storages_invested_available!(m::Model)
    _add_constraint!(
        m,
        :storages_invested_available,
        storages_invested_available_indices,
        _build_constraint_storages_invested_available,
    )
end

function _build_constraint_storages_invested_available(m::Model, n, s, t)
    @fetch storages_invested_available = m.ext[:spineopt].variables
    @build_constraint(
        + storages_invested_available[n, s, t]
        <=
        + candidate_storages(m; node=n, stochastic_scenario=s, t=t)
    )
end
