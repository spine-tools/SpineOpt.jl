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
[storages\_invested](@ref) represents the point-in-time decision to invest in storage at a node ``n`` or not,
while [storages\_invested\_available](@ref) represents the invested-in storages that are available at a node at a
specific time.
This constraint enforces the relationship between [storages\_invested](@ref), [storages\_invested\_available](@ref)
and [storages\_decommissioned](@ref) in adjacent timeslices.

```math
\begin{aligned}
& v^{storages\_invested\_available}_{(n,s,t)} - v^{storages\_invested}_{(n,s,t)}
+ v^{storages\_decommissioned}_{(n,s,t)}
= v^{storages\_invested\_available}_{(n,s,t-1)} \\
& \forall n \in node: p^{candidate\_storages}_{(n)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_storages_invested_transition!(m::Model)
    _add_constraint!(
        m,
        :storages_invested_transition,
        constraint_storages_invested_transition_indices,
        _build_constraint_storages_invested_transition,
    )
end

function _build_constraint_storages_invested_transition(m::Model, n, s_path, t_before, t_after)
    @fetch storages_invested_available, storages_invested, storages_decommissioned = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            + storages_invested_available[n, s, t_after] - storages_invested[n, s, t_after]
            + storages_decommissioned[n, s, t_after]
            for (n, s, t_after) in storages_invested_available_indices(
                m; node=n, stochastic_scenario=s_path, t=t_after
            );
            init=0,
        )
        ==
        sum(
            + storages_invested_available[n, s, t_before]
            for (n, s, t_before) in storages_invested_available_indices(
                m; node=n, stochastic_scenario=s_path, t=t_before
            );
            init=0,
        )
    )
end

function constraint_storages_invested_transition_indices(m::Model)
    (
        (node=n, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (n, t_before, t_after) in node_investment_dynamic_time_indices(m)
        for path in active_stochastic_paths(m, storages_invested_available_indices(m; node=n, t=[t_before, t_after]))
    )
end

"""
    constraint_storages_invested_transition_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:storages_invested_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting array.
"""
function constraint_storages_invested_transition_indices_filtered(
    m::Model;
    node=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_storages_invested_transition_indices(m))
end
