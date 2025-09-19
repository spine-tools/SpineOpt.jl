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
    _add_constraint!(m, :cyclic_node_state, constraint_cyclic_node_state_indices, _build_constraint_cyclic_node_state)
end

function _build_constraint_cyclic_node_state(m::Model, n, s_path, t_start, t_end, blk)
    @fetch node_state = m.ext[:spineopt].variables
    build_sense_constraint(
        sum(
            node_state[n, s, t_end]
            for (n, s, t_end) in node_state_indices(
                m; node=n, stochastic_scenario=s_path, t=t_end, temporal_block=anything
            );
            init=0,
        ),        
        eval(cyclic_condition_sense(node=n, temporal_block=blk)),
        sum(
            node_state[n, s, t_start]
            for (n, s, t_start) in node_state_indices(
                m; node=n, stochastic_scenario=s_path, t=t_start, temporal_block=anything
            );
            init=0,
        )        
    )
end

function constraint_cyclic_node_state_indices(m::Model)
    (
        (node=n, stochastic_path=path, t_start=t_start, t_end=t_end, temporal_block=blk)
        for (n, blk) in indices(cyclic_condition)
        if cyclic_condition(node=n, temporal_block=blk)
        for t_start in _t_start(m, n, blk)
        for t_end in last(collect(time_slice(m; temporal_block=members(blk))))
        for path in active_stochastic_paths(m, node_state_indices(m; node=n, t=[t_start, t_end]))
    )
end

function _t_start(m, n, blk)
    t_start = first(collect(time_slice(m; temporal_block=members(blk))))
    t_before_start = filter!(
        [x.t_before for x in node_dynamic_time_indices(m; node=n, temporal_block=anything, t_after=t_start)]
    ) do t
        !isdisjoint(members(blk), blocks(t))
    end
    if isempty(t_before_start)
        t_start
    else
        t_before_start
    end
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
