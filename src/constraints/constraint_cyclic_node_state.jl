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
To ensure that the node state at the end of the optimization is at least the same value as the initial value
at the beginning of the optimization (or higher),
the cyclic node state constraint can be used by setting the [cyclic\_condition](@ref) of
a [node\_\_temporal\_block](@ref) to `true`. This triggers the following constraint:

```math
v^{node\_state}_{(n, s, start(tb))} \leq  v^{node\_state}_{(n, s, end(tb))}
\qquad \forall (n,tb) \in indices(p^{cyclic\_condition}): p^{cyclic\_condition}_{(n,tb)}
```

See also [cyclic\_condition](@ref).
"""
function add_constraint_cyclic_node_state!(m::Model)
    @fetch node_state = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:cyclic_node_state] = Dict(
        (node=n, stochastic_scenario=s_path, t_start=t_start, t_end=t_end) => @constraint(
            m,
            sum(
                node_state[n, s, t_end]
                for (n, s, t_end) in node_state_indices(m; node=n, stochastic_scenario=s_path, t=t_end);
                init=0,
            )
            >=
            sum(
                node_state[n, s, t_start]
                for (n, s, t_start) in node_state_indices(m; node=n, stochastic_scenario=s_path, t=t_start);
                init=0,
            )
        )
        for (n, s_path, t_start, t_end) in constraint_cyclic_node_state_indices(m)
    )
end

function constraint_cyclic_node_state_indices(m::Model)
    unique(
        (node=n, stochastic_path=path, t_start=t_start, t_end=t_end)
        for (n, blk) in indices(cyclic_condition)
        if cyclic_condition(node=n, temporal_block=blk)
        for t_start in filter(
            x -> blk in blocks(x), t_before_t(m; t_after=first(time_slice(m; temporal_block=members(blk))))
        )
        for t_end in last(time_slice(m; temporal_block=members(blk)))
        for path in active_stochastic_paths(m, node_state_indices(m; node=n, t=[t_start, t_end]))
    )
end

function constraint_cyclic_node_state_indices_filtered(
    m::Model;
    node=anything,
    temporal_block=anything,
    stochastic_path=anything,
    t_start=anything,
    t_end=anything,
)
    function f(ind)
        _index_in(
            ind;
            node=node,
            temporal_block=temporal_block,
            stochastic_path=stochastic_path,
            t_start=t_start,
            t_end=t_end,
        )
    end
    filter(f, constraint_cyclic_node_state_indices(m))
end
