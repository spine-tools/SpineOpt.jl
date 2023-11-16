#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

@doc raw"""
Limit the increase of `unit_flow` over a time period of one `duration_unit` according
to the `start_up_limit` and `ramp_up_limit` parameter values.

```math
\begin{aligned}
& \sum_{
        n \in ng: \neg IRN_{(n)}
}
unit\_flow_{(u,n,d,s,t)} \\
& - \sum_{
        n \in ng: \neg IRN_{(n)}
}
unit\_flow_{(u,n,d,s,t-1)} \\
& + \sum_{
        n \in ng: IRN_{(n)} \land UR_{(n)}
}
unit\_flow_{(u,n,d,s,t)} \\
& \le ( \\
& \qquad \left(SUL_{(u,ng,d,s,t)} - MOP_{(u,ng,d,s,t)} - RUL_{(u,ng,d,s,t)}\right) \cdot units\_started\_up_{(u,s,t)} \\
& \qquad + \left(MOP_{(u,ng,d,s,t)} + RUL_{(u,ng,d,s,t)}\right) \cdot units\_on_{(u,s,t)} \\
& \qquad - MOP_{(u,ng,d,s,t)} \cdot units\_on_{(u,s,t-1)} \\
& ) \cdot UC_{(u,ng,d,s,t)} \cdot UCCF_{(u,ng,d,s,t)} \cdot \Delta t \\
& \forall (u,ng,d) \in indices(RUL) \cup indices(SUL)
\end{aligned}
```
where
- ``IRN =`` [is\_reserve\_node](@ref)
- ``UR =`` [upward\_reserve](@ref)
- ``UC =`` [unit\_capacity](@ref)
- ``UCCF =`` [unit\_conv\_cap\_to\_flow](@ref)
- ``RUL =`` [ramp\_up\_limit](@ref)
- ``SUL =`` [start\_up\_limit](@ref)
- ``MOP =`` [minimum\_operating\_point](@ref)
"""
function add_constraint_ramp_up!(m::Model)
    @fetch units_on, units_started_up, unit_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:ramp_up] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_after)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            - expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_before, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_before)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_after)
                )
                if is_reserve_node(node=n)
                && _switch(d; to_node=upward_reserve, from_node=downward_reserve)(node=n)
                && !is_non_spinning(node=n);
                init=0,
            )
            <=
            + (
                + expr_sum(
                    + (
                        + _start_up_limit(u, ng, d, s, t0, t_after)
                        - _minimum_operating_point(u, ng, d, s, t0, t_after)
                        - _ramp_up_limit(u, ng, d, s, t0, t_after)
                    )
                    * units_started_up[u, s, t]
                    * duration(t)
                    + (_minimum_operating_point(u, ng, d, s, t0, t_after) + _ramp_up_limit(u, ng, d, s, t0, t_after))
                    * units_on[u, s, t]
                    * duration(t)
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    init=0
                )
                - expr_sum(
                    + _minimum_operating_point(u, ng, d, s, t0, t_after)
                    * units_on[u, s, t]
                    * duration(t)
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_before);
                    init=0
                )
            )
            * _unit_flow_capacity(u, ng, d, s, t0, t_after)
            * duration(t_after)
        )
        for (u, ng, d, s, t_before, t_after) in constraint_ramp_up_indices(m)
    )
end

function _ramp_up_limit(u, ng, d, s, t0, t)
    ramp_up_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function constraint_ramp_up_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in Iterators.flatten((indices(ramp_up_limit), indices(start_up_limit)))
        for (u, t_before, t_after) in unit_dynamic_time_indices(m; unit=u)
        for path in active_stochastic_paths(
            m,
            [
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=_overlapping_t(m, t_before, t_after));
                units_on_indices(m; unit=u, t=[t_before; t_after])
            ]
        )
    )
end

"""
    constraint_ramp_up_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:ramp_up` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ramp_up_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    function f(ind)
        _index_in(
            ind;
            unit=unit,
            node=node,
            direction=direction,
            stochastic_path=stochastic_path,
            t_before=t_before,
            t_after=t_after,
        )
    end

    filter(f, constraint_ramp_up_indices(m))
end
