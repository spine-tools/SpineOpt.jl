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
To ensure a minimum storage content, the $v_{node\_state}$ variable needs be constrained by the following equation:

```math
v^{node\_state}_{(n, s, t)} \geq \max(p^{node\_state\_cap}_{(n, s, t)} \cdot p^{node\_state\_min\_factor}_{(n, s, t)}, p^{node\_state\_min}_{(n, s, t)}) \quad \forall n \in node : p^{has\_state}_{(n)}, \, \forall (s,t)
```

Please note that the limit represents the maximum of the two terms.
The first term is the product of the storage capacity and the minimum factor, which is a per-unit value of the storage capacity.
The second term is the minimum state, given in absolute values.
The constraint is only generated if either one of the minimum state parameters is greater than zero and there are candidate storage units.

See also
[node\_state\_cap](@ref),
[node\_state\_min](@ref),
[node\_state\_min\_factor](@ref),
[has\_state](@ref).
"""
function add_constraint_min_node_state!(m::Model)
    _add_constraint!(
        m, :min_node_state, constraint_min_node_state_indices, _build_constraint_min_node_state
    )
end

function _build_constraint_min_node_state(m::Model, ng, s_path, t)
    @fetch node_state, storages_invested_available = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + node_state[n, s, t]
            for (n, s, t) in node_state_indices(m; node=ng, stochastic_scenario=s_path, t=t, temporal_block=anything);
            init=0,
        )
        >=
        + sum(
            + node_state_lower_limit(m; node=ng, stochastic_scenario=s, t=t)
            * (
                + number_of_storages(m; node=ng, stochastic_scenario=s, t=t, _default=_default_nb_of_storages(n))
                + sum(
                    storages_invested_available[n, s, t1]
                    for (n, s, t1) in storages_invested_available_indices(
                        m; node=ng, stochastic_scenario=s_path, t=t_in_t(m; t_short=t)
                    );
                    init=0,
                )
            )
            for (n, s, t) in node_state_indices(m; node=ng, stochastic_scenario=s_path, t=t, temporal_block=anything);
            init=0,
        )
    )
end

function constraint_min_node_state_indices(m::Model)
    (
        (node=ng, stochastic_path=path, t=t)
        for ng in intersect(node(has_state=true), indices(node_state_cap), indices(candidate_storages))
        for t in _node_state_time_slices(m, ng)
        if !_is_zero(node_state_lower_limit(m; node=ng, t=t, _strict=false))
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    node_state_indices(m; node=ng, t=t, temporal_block=anything),
                    storages_invested_available_indices(m; node=ng, t=t_in_t(m; t_short=t)),
                )
            )
        )
    )
end
