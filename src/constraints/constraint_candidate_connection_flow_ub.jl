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
For candidate connections with PTDF-based poweflow, together with [this](@ref constraint_candidate_connection_flow_lb),
this constraint ensures that [connection\_flow](@ref) is zero if the candidate connection is not invested-in
and equals [connection\_intact\_flow](@ref) otherwise.

```math
\begin{aligned}
& v^{connection\_flow}_{(c, n, d, s, t)} 
\leq
v^{connection\_intact\_flow}_{(c, n, d, s, t)} \\
& \forall c \in connection : p^{candidate\_connections}_{(c)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_candidate_connection_flow_ub!(m::Model)
    @fetch connection_flow, connection_intact_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:candidate_connection_flow_ub] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m, connection_flow[conn, ng, d, s, t] <= connection_intact_flow[conn, ng, d, s, t]
        )
        for conn in connection(is_candidate=true, has_ptdf=true)
        for (conn, ng, d, s, t) in connection_flow_indices(m; connection=conn)
    )
end
