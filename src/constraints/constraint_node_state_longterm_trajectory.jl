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
For storage nodes with [is\_longterm\_storage](@ref) set to `true`, the long-term state trajectory
tracks the evolution of [node\_state\_longterm](@ref) across the model horizon when using 
representative periods. The constraint links consecutive long-term time steps by accumulating 
the net change (delta) in the [node\_state](@ref) over the representative blocks that map onto 
the time step $t_{after}$:

```math
\begin{aligned}
& v^{node\_state\_longterm}_{(n, s, t_{after})}
= v^{node\_state\_longterm}_{(n, s, t_{before})}
+ \sum_{blk} p^{representative\_block\_coefficient}_{(t_{after},\, blk)}
\cdot \left(
    v^{node\_state}_{(n, s, t^{last}_{blk})} - v^{node\_state}_{(n, s, t^{first}_{blk})}
\right) \\
& \forall n \in node : p^{has\_state}_{(n)} \land p^{is\_longterm\_storage}_{(n)} \\
& \forall (s,\, t_{before},\, t_{after}) : t_{before} \text{ immediately precedes } t_{after}
\text{ in the long-term temporal structure}
\end{aligned}
```

where $t^{first}_{blk}$ and $t^{last}_{blk}$ are respectively the starting-point time slice
and the last time slice of the representative block $blk$, and 
$p^{representative\_block\_coefficient}_{(t_{after},\, blk)}$ is the weight assigned to 
block $blk$ when constructing the represented time step $t_{after}$ from representative 
periods (see [representative\_periods\_mapping](@ref)).

!!! note
    This constraint is part of the **delta formulation** for long-term storage.
    Instead of carrying the absolute [node\_state](@ref) across the full planning horizon
    at fine time resolution, it propagates the long-term storage level by adding the net
    change accumulated over each representative block. This allows to partially recover
    the chronology in models that use representative periods to track seasonal or 
    inter-period storage.

See also
[has\_state](@ref),
[is\_longterm\_storage](@ref),
[representative\_periods\_mapping](@ref),
[node\_state\_longterm](@ref),
[node\_state](@ref).
"""
function add_constraint_node_state_longterm_trajectory!(m::Model)
    _add_constraint!(
        m,
        :node_state_longterm_trajectory,
        constraint_node_state_longterm_trajectory_indices,
        _build_constraint_node_state_longterm_trajectory,
    )
end

function _build_constraint_node_state_longterm_trajectory(m::Model, n, s, t_before, t_after)
    @fetch node_state_longterm = m.ext[:spineopt].variables
    @build_constraint(
        + node_state_longterm[n, s, t_after]
        ==
        + node_state_longterm[n, s, t_before]
        + sum(coef * _block_delta(m, n, s, blk) for (blk, coef) in representative_block_coefficients(m, t_after))
    )
end

function _block_delta(m, n, s, blk)
    last_t = last(time_slice(m; temporal_block=blk))
    first_t = only(time_slice(m; temporal_block=block__starting_point(temporal_block1=blk)))
    @fetch node_state = m.ext[:spineopt].variables
    (
        + sum(node_state[n, s, t] for (n, s, t) in node_state_indices(m; node=n, stochastic_scenario=s, t=last_t))
        - sum(node_state[n, s, t] for (n, s, t) in node_state_indices(m; node=n, stochastic_scenario=s, t=first_t))
    )
end

function constraint_node_state_longterm_trajectory_indices(m::Model)
    (
        (node=n, stochastic_scenario=s, t_before=t_before, t_after=t_after)
        for (n, s, t_after) in node_state_longterm_indices(m)
        for t_before in Iterators.take(
            (
                x.t
                for x in node_state_longterm_indices(
                    m; node=n, stochastic_scenario=s, t=t_before_t(m; t_after=t_after)
                )
            ),
            1,
        )
    )
end