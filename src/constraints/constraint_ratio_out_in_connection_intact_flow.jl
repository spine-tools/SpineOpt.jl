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
For PTDF-based lossless DC power flow, ensures that the output flow to the ``to\_node``
equals the input flow from the ``from\_node``.

```math
\begin{aligned}              
& v^{connection\_intact\_flow}_{(c, n_{out}, d_{to}, s, t)}
=
v^{connection\_intact\_flow}_{(c, n_{in}, d_{from}, s, t)} \\
& \forall c \in connection : p^{is\_monitored}_{(c)} \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_ratio_out_in_connection_intact_flow!(m::Model)
    use_connection_intact_flow(model=m.ext[:spineopt].instance) || return
    _add_constraint!(
        m,
        :ratio_out_in_connection_intact_flow,
        constraint_ratio_out_in_connection_intact_flow_indices,
        _build_constraint_ratio_out_in_connection_intact_flow,
    )
end

function _build_constraint_ratio_out_in_connection_intact_flow(m::Model, conn, ng_out, ng_in, s_path, t)
    @fetch connection_intact_flow = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + connection_intact_flow[conn, n_out, d, s, t_short] * duration(t_short)
            for (conn, n_out, d, s, t_short) in connection_intact_flow_indices(
                m;
                connection=conn,
                node=ng_out,
                direction=direction(:to_node),
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        ==
        + sum(
            + connection_intact_flow[conn, n_in, d, s, t_short] * duration(t_short)
            for (conn, n_in, d, s, t_short) in connection_intact_flow_indices(
                m;
                connection=conn,
                node=ng_in,
                direction=direction(:from_node),
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
    )
end

function constraint_ratio_out_in_connection_intact_flow_indices(m::Model)
    (
        (connection=conn, node1=n_out, node2=n_in, stochastic_path=path, t=t)
        for conn in connection(connection_monitored=true, has_ptdf=true)
        for (n_in, n_out) in connection__node__node(connection=conn)
        for (t, path) in t_lowest_resolution_path(
            m, 
            Iterators.flatten(
                (
                    connection_intact_flow_indices(m; connection=conn, node=n_out, direction=direction(:to_node)),
                    connection_intact_flow_indices(m; connection=conn, node=n_in, direction=direction(:from_node)),
                )
            )
        )
    )
end

"""
    constraint_ratio_out_in_connection_intact_flow_indices_filtered(m::Model; filtering_options...)

For investments with PTDF based flows, constraint the intact flow into a node to be equal to the flow out of the node.

Uses stochastic path indices due to potentially different stochastic structures between `connection_intact_flow` variables.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_out_in_connection_intact_flow_indices_filtered(
    m::Model;
    connection=connection(connection_monitored=true, has_ptdf=true),
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_out_in_connection_intact_flow_indices(m))
end