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
Implements a standard piecewise linear heat-rate function where [unit\_flow](@ref) from a (input fuel consumption) node
is equal to the sum over operating point segments of [unit\_flow\_op](@ref) to a (output electricity node) node
times the corresponding [incremental\_heat\_rate](@ref).

```math
\begin{aligned}
& v^{unit\_flow}_{(u, n_{in}, d, s, t)} \\
& = \sum_{op=1}^{\left\|p^{operating\_points}_{(u,n,d)}\right\|} p^{unit\_incremental\_heat\_rate}_{(u, n_{in}, n_{out}, op, s, t)}
\cdot v^{unit\_flow\_op}_{(u, n_{out}, d, op, s, t)} \\
& + p^{unit\_idle\_heat\_rate}_{(u, n_{in}, n_{out}, s, t)} \cdot v^{units\_on}_{(u, s, t)} \\
& + p^{unit\_start\_flow}_{(u, n_{in}, n_{out}, s, t)} \cdot v^{units\_started\_up}_{(u, s, t)} \\
& \forall (u,n_{in},n_{out}) \in indices(p^{unit\_incremental\_heat\_rate}) \\
& \forall (s,t)
\end{aligned}
```

See also
[unit\_incremental\_heat\_rate](@ref),
[unit\_idle\_heat\_rate](@ref),
[unit\_start\_flow](@ref).
"""
function add_constraint_unit_pw_heat_rate!(m::Model)
    @fetch unit_flow, unit_flow_op, units_on, units_started_up = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_pw_heat_rate] = Dict(
        (unit=u, node1=n_from, node2=n_to, stochastic_path=s_path, t=t) => @constraint(
            m,
            sum(
                + unit_flow[u, n, d, s, t_short] * duration(t_short)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n_from,
                    direction=direction(:from_node),
                    stochastic_scenario=s_path,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            ==
            + sum(
                + unit_flow_op[u, n, d, op, s, t_short]
                * unit_incremental_heat_rate[
                    (unit=u, node1=n_from, node2=n, i=op, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short)
                for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    m;
                    unit=u,
                    node=n_to,
                    direction=direction(:to_node),
                    stochastic_scenario=s_path,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            + sum(
                + unit_flow[u, n, d, s, t_short]
                * unit_incremental_heat_rate[
                    (unit=u, node1=n_from, node2=n, i=1, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n_to,
                    direction=direction(:to_node),
                    stochastic_scenario=s_path,
                    t=t_in_t(m; t_long=t),
                )
                if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
                init=0,
            )
            + sum(
                + units_on[u, s, t1]
                * min(duration(t1), duration(t))
                * unit_idle_heat_rate[
                   (unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, analysis_time=t0, t=t)
                ]
                + units_started_up[u, s, t1]
                * unit_start_flow[
                    (unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, analysis_time=t0, t=t)
                ]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t));
                init=0,
            )
        )
        for (u, n_from, n_to, s_path, t) in constraint_unit_pw_heat_rate_indices(m)
    )
end

function constraint_unit_pw_heat_rate_indices(m::Model)
    (
        (unit=u, node_from=n_from, node_to=n_to, stochastic_path=path, t=t)
        for (u, n_from, n_to) in indices(unit_incremental_heat_rate)
        for (t, path) in t_lowest_resolution_path(
            m, 
            unit_flow_indices(m; unit=u, node=[n_from; n_to]),
            Iterators.flatten(
                (
                    unit_flow_indices(m; unit=u, node=n_from, direction=direction(:from_node)),
                    unit_flow_indices(m; unit=u, node=n_to, direction=direction(:to_node)),
                    units_on_indices(m; unit=u),
                )
            )
        )
    )
end

"""
    constraint_unit_pw_heat_rate_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `unit_pw_heat_rate` constraint

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and
`units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_pw_heat_rate_indices_filtered(
    m::Model,
    unit=anything,
    node_from=anything,         #input "fuel" node
    node_to=anything,           #output "electricity" node
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node_from=node_from, node_to=node_to, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_pw_heat_rate_indices(m))
end