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
The number of available invested-in connections at any point in time is less than the number of
investment candidate connections.

```math
\begin{aligned}
& v^{connections\_invested\_available}_{(c,s,t)} < p^{candidate\_connections}_{(c)} \\
& \forall c \in connection: p^{candidate\_connections}_{(c)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connections_invested_available!(m::Model)
    _add_constraint!(
        m,
        :connections_invested_available,
        connections_invested_available_indices,
        _build_constraint_connections_invested_available,
    )
end

function _build_constraint_connections_invested_available(m::Model, conn, s, t)
    @fetch connections_invested_available = m.ext[:spineopt].variables
    @build_constraint(
        + connections_invested_available[conn, s, t]
        <=
        + candidate_connections(m; connection=conn, stochastic_scenario=s, t=t)
    )
end
