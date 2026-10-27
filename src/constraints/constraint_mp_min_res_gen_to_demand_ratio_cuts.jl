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
Imposes a minimum share of renewable generation in the Benders master problem.
For each [grid](@ref) with [mp\_min\_res\_gen\_to\_demand\_ratio](@ref) defined, renewable generation
must be at least that share of the total demand of the nodes in the grid ([node\_\_grid](@ref)).
Renewable units are those with [is\_renewable](@ref) set to `true`.

Each Benders iteration adds one cut. It takes the renewable generation from the latest sub problem solution
and corrects it for changes in the investments in renewable units:

```math
\begin{aligned}
& \sum_{(u,n) \in R_g} \sum_{(s,t)} \Big( p^{unit\_flow}_{(b,u,n,s,t)} \\
& \qquad + \left( v^{units\_invested\_available}_{(u,s,t)} - p^{units\_invested\_available}_{(b,u,s,t)} \right)
\cdot p^{availability\_factor}_{(u,s,t)} \cdot p^{capacity\_per\_unit}_{(u,n,s,t)}
\cdot p^{capacity\_to\_flow\_conversion\_factor}_{(u,n,s,t)} \Big) \cdot \Delta t \\
& + v^{mp\_min\_res\_gen\_to\_demand\_ratio\_slack}_{(g)} \\
& \geq p^{mp\_min\_res\_gen\_to\_demand\_ratio}_{(g)} \cdot \sum_{n \in g} \sum_{(s,t)}
\left( p^{demand}_{(n,s,t)} + p^{demand\_fraction}_{(n,s,t)} \cdot p^{demand}_{(ng,s,t)} \right) \cdot \Delta t \\
& \forall g \in indices(p^{mp\_min\_res\_gen\_to\_demand\_ratio})
\end{aligned}
```

where
- ``R_g`` is the set of [unit\_\_to\_node](@ref) pairs with a renewable unit ``u`` and a node ``n`` in grid ``g``,
- ``p^{unit\_flow}_{(b,u,n,s,t)}`` is the [unit\_flow](@ref var_unit_flow) in the sub problem solution of Benders iteration ``b``,
- ``p^{units\_invested\_available}_{(b,u,s,t)}`` is the value of
  [units\_invested\_available](@ref var_units_invested_available) used in the sub problem in iteration ``b``,
- ``ng`` is a node group that node ``n`` belongs to,
- the sums over ``t`` cover the sub problem time windows and the sums over ``s`` cover the scenarios
  of each unit's or node's stochastic structure.

The slack variable is only created if [mp\_min\_res\_gen\_to\_demand\_ratio\_slack\_penalty](@ref) is defined,
and it is penalised with that value in the master problem objective. Without it, the constraint is hard.

See also
[mp\_min\_res\_gen\_to\_demand\_ratio](@ref),
[mp\_min\_res\_gen\_to\_demand\_ratio\_slack\_penalty](@ref),
[is\_renewable](@ref)
"""
function add_constraint_mp_min_res_gen_to_demand_ratio_cuts!(m_mp, m)
    @fetch units_invested_available, mp_min_res_gen_to_demand_ratio_slack = m_mp.ext[:spineopt].variables
    benders_units_invested_available = m_mp.ext[:spineopt].downstream_outputs[:units_invested_available]
    sp_unit_flow = _val_by_ent(m, :unit_flow)
    merge!(
        get!(m_mp.ext[:spineopt].constraints, :mp_min_res_gen_to_demand_ratio_cuts, Dict()),
        Dict(
            (benders_iteration=bi, grid=comm) => @constraint(
                m_mp,
                + sum(
                    window_sum_duration(
                        m_mp, sp_unit_flow[(unit=u, node=n, direction=d, stochastic_scenario=s)], window
                    )
                    for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in _unit_scenario(unit(is_renewable=true))
                    for (u, n, d) in unit__to_node(unit=u, node=node__grid(grid=comm), _compact=false);
                    init=0
                )
                + sum(
                    sum(
                        + units_invested_available[u, s, t]
                        - benders_units_invested_available[(unit=u, stochastic_scenario=s)](t=t)
                        for (u, s, t) in units_invested_available_indices(
                            m_mp; unit=u, stochastic_scenario=s, t=to_time_slice(m_mp; t=window)
                        );
                        init=0
                    )
                    * window_sum_duration(
                        m_mp,
                        + availability_factor(unit=u, stochastic_scenario=s)
                        * capacity_per_unit(unit=u, node=n, direction=d, stochastic_scenario=s)
                        * capacity_to_flow_conversion_factor(unit=u, node=n, direction=d, stochastic_scenario=s),
                        window
                    )
                    for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in _unit_scenario(unit(is_renewable=true)) 
                    for (u, n, d) in unit__to_node(unit=u, node=node__grid(grid=comm), _compact=false);
                    init=0,
                )
                + get(mp_min_res_gen_to_demand_ratio_slack, (comm,), 0)
                >=
                + mp_min_res_gen_to_demand_ratio(grid=comm)
                * (
                    sum(
                        window_sum_duration(m_mp, demand(node=n, stochastic_scenario=s), window)
                        for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in _node_scenario(intersect(indices(demand), node__grid(grid=comm)));
                        init=0
                    )
                    + sum(
                        window_sum_duration(
                            m_mp,
                            demand_fraction(node=n, stochastic_scenario=s) * demand(node=ng, stochastic_scenario=s),
                            window
                        )
                        for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in _node_scenario(
                            intersect(indices(demand_fraction), node__grid(grid=comm))
                        )
                        for ng in groups(n);
                        init=0
                    )
                )
            )
            for bi in last(benders_iteration())
            for comm in indices(mp_min_res_gen_to_demand_ratio)
        )
    )
end

function _node_scenario(node)
    (
        (node=n, stochastic_scenario=s)
        for (n, ss) in node__stochastic_structure(node=node, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function _unit_scenario(unit)
    (
        (unit=u, stochastic_scenario=s)
        for (u, ss) in units_on__stochastic_structure(unit=unit, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function window_sum_duration(m, ts::TimeSeries, window; init=0)
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    time_slice_value_iter = (
        (TimeSlice(t1, t2; duration_unit=dur_unit), v) for (t1, t2, v) in zip(ts.indexes, ts.indexes[2:end], ts.values)
    )
    sum(v * duration(t) for (t, v) in time_slice_value_iter if iscontained(start(t), window) && !isnan(v); init=init)
end
window_sum_duration(m, x::Number, window; init=0) = x * duration(window) + init
