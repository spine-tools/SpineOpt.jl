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
To limit the storage content, the $v_{node\_state}$ variable needs be constrained by the following equation:

```math
v^{node\_state}_{(n, s, t)} \leq p^{node\_state\_cap}_{(n, s, t)} \quad \forall n \in node : p^{has\_state}_{(n)}, \, \forall (s,t)
```

The discharging and charging behavior of storage nodes can be described through unit(s),
representing the link between the storage node and the supply node.
Note that the dis-/charging efficiencies and capacities are properties of these units.
See the [capacity constraint](@ref constraint_unit_flow_capacity) and
the [unit flow ratio constraints](@ref constraint_ratio_unit_flow).

See also
[node\_state\_cap](@ref),
[has\_state](@ref).
"""
function add_constraint_node_state_capacity!(m::Model)
    @fetch node_state, storages_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:node_state_capacity] = Dict(
        (node=ng, stochastic_scenario=s_path, t=t) => @constraint(
            m,
            + sum(
                + node_state[n, s, t]
                for (n, s, t) in node_state_indices(m; node=ng, stochastic_scenario=s_path, t=t);
                init=0,
            )
            <=
            + sum(
                node_state_cap[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (n, s, t) in node_state_indices(m; node=ng, stochastic_scenario=s_path, t=t);
                init=0,
            )
            * (
                candidate_storages(node=ng) !== nothing ?
                sum(
                    storages_invested_available[n, s, t1]
                    for (n, s, t1) in storages_invested_available_indices(
                        m; node=ng, stochastic_scenario=s_path, t=t_in_t(m; t_short=t)
                    );
                    init=0,
                ) : 1
            )
        )
        for (ng, s_path, t) in constraint_node_state_capacity_indices(m)
    )
end

function constraint_node_state_capacity_indices(m::Model)
    unique(
        (node=ng, stochastic_path=path, t=t)
        for (ng, t) in node_time_indices(m; node=indices(node_state_cap))
        for path in active_stochastic_paths(
            m,
            vcat(
                node_state_indices(m; node=ng, t=t),
                storages_invested_available_indices(m; node=ng, t=t_in_t(m; t_short=t))
            )
        )
    )
end

"""
    constraint_node_state_capacity_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:constraint_node_state_capacity` constraint.

Uses stochastic path indices of the `node_state` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_node_state_capacity_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_node_state_capacity_indices(m))
end