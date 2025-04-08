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
[connections\_invested](@ref) represents the point-in-time decision to invest in a connection or not while
[connections\_invested\_available](@ref) represents the invested-in connections that are available at a specific time.
This constraint enforces the relationship between [connections\_invested](@ref), [connections\_invested\_available](@ref) and
[connections\_decommissioned](@ref) in adjacent timeslices.

```math
\begin{aligned}
& v^{connections\_invested\_available}_{(c,s,t)} - v^{connections\_invested}_{(c,s,t)}
+ v^{connections\_decommissioned}_{(c,s,t)} \\
& = v^{connections\_invested\_available}_{(c,s,t-1)} \\
& \forall c \in connection: p^{candidate\_connections}_{(c)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connections_invested_transition!(m::Model)
    _add_constraint!(
        m,
        :connections_invested_transition,
        constraint_connections_invested_transition_indices,
        _build_constraint_connections_invested_transition,
    )
end

function _build_constraint_connections_invested_transition(m::Model, conn, s_path, t_before, t_after)
    @fetch connections_invested_available, connections_invested, connections_decommissioned = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            + connections_invested_available[conn, s, t_after]
            - connections_invested[conn, s, t_after]
            + connections_decommissioned[conn, s, t_after]
            for (conn, s, t_after) in connections_invested_available_indices(
                m; connection=conn, stochastic_scenario=s_path, t=t_after
            );
            init=0,
        )
        ==
        sum(
            + connections_invested_available[conn, s, t_before]
            for (conn, s, t_before) in connections_invested_available_indices(
                m; connection=conn, stochastic_scenario=s_path, t=t_before
            );
            init=0,
        )
    )
end

function constraint_connections_invested_transition_indices(m::Model)
    (
        (connection=conn, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (conn, t_before, t_after) in connection_investment_dynamic_time_indices(m)
        for path in active_stochastic_paths(
            m, connections_invested_available_indices(m; connection=conn, t=[t_before, t_after])
        )
    )
end

"""
    constraint_connections_invested_transition_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connections_invested_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting array.
"""
function constraint_connections_invested_transition_indices_filtered(
    m::Model;
    connection=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; connection=connection, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_connections_invested_transition_indices(m))
end
