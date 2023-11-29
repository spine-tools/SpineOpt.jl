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
    @fetch storages_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:storages_invested_available] = Dict(
        (node=n, stochastic_scenario=s, t=t) => @constraint(
            m,
            + storages_invested_available[n, s, t]
            <=
            + candidate_storages[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
        )
        for (n, s, t) in storages_invested_available_indices(m)
    )
end
