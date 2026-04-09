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
Enforces the relationship between [connection\_intact\_flow](@ref) (flow with all investments assumed in force)
and [connection\_flow](@ref). This constraint ensures that the
[connection\_flow](@ref) is [connection\_intact\_flow](@ref) plus additional flow contributions
from investment connections that are not invested in.

```math
\begin{aligned}
& \left(v^{connection\_flow}_{(c, n_{to}, from\_node, s, t)}
- v^{connection\_flow}_{(c, n_{to}, to\_node, s, t)} \right)
- \left(v^{connection\_intact\_flow}_{(c, n_{to}, from\_node, s, t)}
- v^{connection\_intact\_flow}_{(c, n_{to}, to\_node, s, t)} \right) \\
& =\\
& \sum_{c_{cand}} p^{lodf}_{(c_{cand}, c)} \cdot \left[p^{candidate\_connections}_{(c_{cand})} \neq 0 \right] \cdot \Big( \\
& \qquad \left(
    v^{connection\_flow}_{(c_{cand}, n_{to\_cand}, from\_node, s, t)}
    - v^{connection\_flow}_{(c_{cand}, n_{to\_cand}, to\_node, s, t)} 
\right)
\\
& \qquad 
- \left(
    v^{connection\_intact\_flow}_{(c_{cand}, n_{to\_cand}, from\_node, s, t)}
    - v^{connection\_intact\_flow}_{(c_{cand}, n_{to\_cand}, to\_node, s, t)}
\right)
\\
& \Big) \\
& \forall c \in connection : p^{is\_monitored}_{(c)} \land p^{candidate\_connections}_{(c)} = 0 \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connection_flow_intact_flow!(m::Model)
    use_connection_intact_flow(model=m.ext[:spineopt].instance) || return
    _add_constraint!(
        m,
        :connection_flow_intact_flow,
        constraint_connection_flow_intact_flow_indices,
        _build_constraint_connection_flow_intact_flow,
    )
end

function _build_constraint_connection_flow_intact_flow(m, conn, ng, s_path, t)
    @fetch connection_flow, connection_intact_flow = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + connection_flow[conn, n, direction(:from_node), s, t] * duration(t)
            - connection_flow[conn, n, direction(:to_node), s, t] * duration(t)
            - connection_intact_flow[conn, n, direction(:from_node), s, t] * duration(t)
            + connection_intact_flow[conn, n, direction(:to_node), s, t] * duration(t)
            for (conn, n, d, s, t) in connection_flow_indices(
                m;
                connection=conn,
                direction=direction(:from_node),
                node=ng,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        ==
        + sum(
            + lodf(connection1=candidate_conn, connection2=conn)
            * (
                + connection_intact_flow[candidate_conn, n, direction(:from_node), s, t] * duration(t)
                - connection_intact_flow[candidate_conn, n, direction(:to_node), s, t] * duration(t)
                - connection_flow[candidate_conn, n, direction(:from_node), s, t] * duration(t)
                + connection_flow[candidate_conn, n, direction(:to_node), s, t] * duration(t)
            )
            for candidate_conn in _candidate_connections(conn)
            for n in last(connection__from_node(connection=candidate_conn))
            for (candidate_conn, n, d, s, t) in connection_flow_indices(
                m;
                connection=candidate_conn,
                node=n,
                direction=direction(:from_node),
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
    )
end

function constraint_connection_flow_intact_flow_indices(m::Model)
    (
        (connection=conn, node=n_to, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true, is_candidate=false)
        for (conn, n_to, d_to) in Iterators.drop(connection__from_node(connection=conn; _compact=false), 1)
        for (t, path) in t_lowest_resolution_path(
            m, 
            x
            for conn_ in Iterators.flatten(((conn,), _candidate_connections(conn)))
            for x in connection_flow_indices(m; connection=conn_, last(connection__from_node(connection=conn_))...)
        )
    )
end

"""
    constraint_connection_flow_intact_flow_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:connection_flow_intact_flow` constraint.

Uses stochastic path indices of the `connection_flow` and `connection_intact_flow` variables. Only the lowest
resolution time slices are included, as the `:connection_flow_capacity` is used to constrain the "average power" of the
`connection` instead of "instantaneous power". Keyword arguments can be used to filter the resulting
"""
function constraint_connection_flow_intact_flow_indices_filtered(
    m::Model;
    connection=anything,
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_connection_flow_intact_flow_indices(m))
end

"""
    _candidate_connections(conn)

An iterator over all candidate connections that can impact the flow on the given connection.
"""
function _candidate_connections(conn)
    (
        candidate_conn
        for candidate_conn in connection(is_candidate=true, has_ptdf=true)
        if candidate_conn !== conn && lodf(connection1=candidate_conn, connection2=conn, _strict=false) !== nothing
    )
end