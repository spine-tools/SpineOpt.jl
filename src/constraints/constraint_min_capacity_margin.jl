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
The capacity margin must be greater than or equal to [min\_capacity\_margin](@ref).
If [min\_capacity\_margin\_penalty](@ref) is specified, the [min\_capacity\_margin\_slack](@ref)
variable is added which is penalised with the corresponding coefficient in the objective function.
This encourages maintenance outages to be scheduled at times of higher capacity margin and can 
allow low capacity margin to influence investment decisions.

```math
\begin{align*}
+ expr^{capacity\_margin}_{(n,s,t)} \\
+ v^{min\_capacity\_margin\_slack}_{(n,s,t)}
& >= \\
& p^{min\_capacity\_margin}_{(n,s,t)} \\
& \forall n \in node: p^{min\_capacity\_margin}_{(n)}\\
\end{align*}
```

See also
[capacity\_margin](@ref),
[min\_capacity\_margin](@ref),
[min\_capacity\_margin\_penalty](@ref)
"""
function add_constraint_min_capacity_margin!(m::Model)
    _add_constraint!(m, :min_capacity_margin, expression_capacity_margin_indices, _build_constraint_min_capacity_margin)
end

function _build_constraint_min_capacity_margin(m::Model, n, s_path, t)
    @fetch min_capacity_margin_slack = m.ext[:spineopt].variables
    @fetch capacity_margin = m.ext[:spineopt].expressions    
    @build_constraint(
        + capacity_margin[n, s_path, t]
        + sum(
            min_capacity_margin_slack[n, s, t]
            for (n, s, t) in min_capacity_margin_slack_indices(m; node=n, stochastic_scenario=s_path, t=t);
            init=0,
        )
        >=
        + sum(
            min_capacity_margin(m; node=n, stochastic_scenario=s, t=t)
            for (n, s, t) in node_stochastic_time_indices(m; node=n, stochastic_scenario=s_path, t=t);
            init=0,
        )
    )
end
