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
For candidate connections with PTDF-based poweflow, together with [this](@ref constraint_candidate_connection_flow_ub),
this constraint ensures that [connection\_flow](@ref) is zero if the candidate connection is not invested-in and
equals [connection\_intact\_flow](@ref) otherwise.

```math
\begin{aligned}
& v^{connection\_flow}_{(c, n, d, s, t)} \\
& \geq \\
& v^{connection\_intact\_flow}_{(c, n, d, s, t)}
- p^{connection\_capacity}_{(c, n, d, s, t)} \cdot \left(
    p^{candidate\_connections}_{(c, s, t)} - v^{connections\_invested\_available}_{(c, s, t)} \right) \\
& \forall c \in connection : p^{candidate\_connections}_{(c)} \neq 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_candidate_connection_flow_lb!(m::Model)
    use_connection_intact_flow(model=m.ext[:spineopt].instance) || return
    _add_constraint!(
        m,
        :candidate_connection_flow_lb,
        constraint_candidate_connection_flow_lb_indices,
        _build_constraint_candidate_connection_flow_lb,
    )
end

function _build_constraint_candidate_connection_flow_lb(m::Model, conn, n, d, s_path, t)
    @fetch connection_flow, connection_intact_flow, connections_invested_available = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            connection_flow[conn, n, d, s, t] * duration(t)
            for (conn, n, d, s, t) in connection_flow_indices(
                m; connection=conn, direction=d, node=n, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        >=
        + sum(
            connection_intact_flow[conn, n, d, s, t] * duration(t)
            for (conn, n, d, s, t) in connection_intact_flow_indices(
                m; connection=conn, direction=d, node=n, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        - (
            + candidate_connections(connection=conn)
            - sum(
                connections_invested_available[conn, s, t1]
                for (conn, s, t1) in connections_invested_available_indices(
                    m; connection=conn, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
                );
                init=0,
            )
        )
        * sum(
            connection_capacity(m; connection=conn, node=n, direction=d, stochastic_scenario=s, t=t, _default=1e6)
            * duration(t)
            for (conn, n, d, s, t) in connection_intact_flow_indices(
                m; connection=conn, direction=d, node=n, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
    )
end

function constraint_candidate_connection_flow_lb_indices(m::Model)
    (
        (connection=conn, node=n, direction=d, stochastic_path=path, t=t)
        for (conn, n, d, s, t) in connection_flow_indices(m; connection=connection(is_candidate=true, has_ptdf=true))
        for (t, path) in t_lowest_resolution_path(
            m,
            Iterators.flatten(
                (
                    connection_flow_indices(m; connection=conn, node=n, direction=d),
                    connections_invested_available_indices(m; connection=conn),
                )
            )
        )
    )
end

"""
    constraint_candidate_connection_flow_lb_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_intact_flow_lb` constraint.

Uses stochastic path indices of the `connection_flow` variables. Only the lowest resolution time slices are included,
as the `:connection_flow_capacity` is used to constrain the "average power" of the `connection`
instead of "instantaneous power". Keyword arguments can be used to filter the resulting indices
"""
function constraint_candidate_connection_flow_lb_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_candidate_connection_flow_lb_indices(m))
end
