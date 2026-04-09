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
If a compression station is located in between two nodes, the connection is considered to be active
and a compression ratio between the two nodes can be imposed.
The parameter [compression\_factor](@ref) needs to be defined on a [connection\_\_node\_\_node](@ref) relationship,
where the first node corresponds the origin node, before the compression,
while the second node corresponds to the destination node, after compression.
The existence of this parameter will trigger the following constraint:

```math
\begin{aligned}
& \sum_{n \in ng2} v^{node\_pressure}_{(n,s,t)} \leq p^{compression\_factor}_{(conn,ng1,ng2,s,t)} \cdot \sum_{n \in ng1} v^{node\_pressure}_{(n,s,t)} \\
& \forall (conn,ng1,ng2) \in indices(p^{compression\_factor}) \\
& \forall (s,t)
\end{aligned}
```

See also [compression\_factor](@ref).
"""
function add_constraint_compression_ratio!(m::Model)
    _add_constraint!(m, :compression_ratio, constraint_compression_ratio_indices, _build_constraint_compression_ratio)
end

function _build_constraint_compression_ratio(m::Model, conn, n_orig, n_dest, s_path, t)
    @fetch node_pressure = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            node_pressure[n_dest, s, t] * duration(t)
            for (n_dest, s, t) in node_pressure_indices(
                m; node=n_dest, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        <=
        + sum(
            node_pressure[n_orig, s, t]
            * compression_factor(m; connection=conn, node1=n_orig, node2=n_dest, stochastic_scenario=s, t=t)
            * duration(t)
            for (n_orig, s, t) in node_pressure_indices(
                m; node=n_orig, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
    )
end

function constraint_compression_ratio_indices(m::Model)
    (
        (connection=conn, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (conn, n1, n2) in indices(compression_factor)
        for (t, path) in t_lowest_resolution_path(m, node_pressure_indices(m; node=[n1, n2]))
    )
end

"""
    constraint_compression_ratio_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:compression_ratio` constraint.

Uses stochastic path indices of the `node_pressure` variables. Only the lowest resolution time slices are included,
as the `:compression_factor` is used to constrain the "average compression ratio" of the `connection`.
Keyword arguments can be used to filter the resulting
"""
function constraint_compression_ratio_indices_filtered(
    m::Model;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_compression_ratio_indices(m))
end
