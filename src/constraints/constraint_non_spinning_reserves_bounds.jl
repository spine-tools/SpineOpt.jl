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
Sets a lower bound on the non-spinning reserve provided by a [unit](@ref).
A unit that is started up (or shut down) to provide non-spinning reserve must run at least at its
[minimum\_operating\_point](@ref), so the reserve it provides cannot be lower than that.
The constraint is generated for each [unit\_\_to\_node](@ref) and [node\_\_to\_unit](@ref) with
[capacity\_per\_unit](@ref) defined, where the node or node group includes a non-spinning reserve node
([reserve\_active](@ref) and [is\_non\_spinning](@ref) set to `true`):

```math
\begin{aligned}
& p^{minimum\_operating\_point}_{(u,ng,d,s,t)} \cdot p^{capacity\_per\_unit}_{(u,ng,d,s,t)}
\cdot \sum_{n \in ng} v^{nonspin\_units}_{(u,n,s,t)} \\
& \leq \sum_{n \in ng: \, p^{is\_non\_spinning}_{(n)}} v^{unit\_flow}_{(u,n,d,s,t)} \\
& \forall (u,ng,d) \in indices(p^{capacity\_per\_unit}): \exists n \in ng: p^{reserve\_active}_{(n)} \land p^{is\_non\_spinning}_{(n)} \\
& \forall (s,t)
\end{aligned}
```

where ``v^{nonspin\_units}`` is [nonspin\_units\_started\_up](@ref var_nonspin_units_started_up)
for flows to a node (``d = to\_node``) and [nonspin\_units\_shut\_down](@ref var_nonspin_units_shut_down)
for flows from a node (``d = from\_node``).
The formulation is shown for a single time resolution; with different resolutions,
both sides are weighted by the time-slice durations.
If [minimum\_operating\_point](@ref) is not defined, the lower bound is zero.

See also
[is\_non\_spinning](@ref),
[minimum\_operating\_point](@ref)
"""
function add_constraint_non_spinning_reserves_lower_bound!(m::Model)
    _add_constraint!(
        m,
        :non_spinning_reserves_lower_bound,
        constraint_non_spinning_reserves_bounds_indices,
        _build_constraint_non_spinning_reserves_lower_bound,
    )
end

function _build_constraint_non_spinning_reserves_lower_bound(m::Model, u, ng, d, s_path, t)
    @fetch unit_flow, nonspin_units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            + minimum_operating_point(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_over, _default=0)
            * capacity_per_unit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_over)
            * _switch(d; from_node=nonspin_units_shut_down, to_node=nonspin_units_started_up)[u, n, s, t_over]
            * min(duration(t), duration(t_over))
            for (u, n, s, t_over) in _switch(
                d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices
            )(m; unit=u, node=ng, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t));
            init=0,
        )
        <=
        sum(
            unit_flow[u, n, d, s, t_short] * duration(t_short)
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            )
            if reserve_active(node=n) && is_non_spinning(node=n);
            init=0,
        )
    )
end

@doc raw"""
Sets an upper bound on the non-spinning reserve provided by a [unit](@ref), based on [ramp\_limits\_startup](@ref).
The constraint is generated for the same unit flows as the
[lower bound on non-spinning reserves](@ref constraint_non_spinning_reserves_lower_bound):

```math
\begin{aligned}
& \sum_{n \in ng: \, p^{is\_non\_spinning}_{(n)}} v^{unit\_flow}_{(u,n,d,s,t)} \\
& \leq p^{ramp\_limits\_startup}_{(u,ng,d,s,t)} \cdot p^{capacity\_per\_unit}_{(u,ng,d,s,t)}
\cdot \sum_{n \in ng} v^{nonspin\_units}_{(u,n,s,t)} \\
& \forall (u,ng,d) \in indices(p^{capacity\_per\_unit}): \exists n \in ng: p^{reserve\_active}_{(n)} \land p^{is\_non\_spinning}_{(n)} \\
& \forall (s,t)
\end{aligned}
```

where ``v^{nonspin\_units}`` is [nonspin\_units\_started\_up](@ref var_nonspin_units_started_up)
for flows to a node (``d = to\_node``) and [nonspin\_units\_shut\_down](@ref var_nonspin_units_shut_down)
for flows from a node (``d = from\_node``).
The formulation is shown for a single time resolution; with different resolutions,
both sides are weighted by the time-slice durations.
If [ramp\_limits\_startup](@ref) is not defined, it defaults to 1, i.e. the full capacity of the units.

See also
[is\_non\_spinning](@ref),
[ramp\_limits\_startup](@ref)
"""
function add_constraint_non_spinning_reserves_start_up_upper_bound!(m::Model)
    _add_constraint_non_spinning_reserves_upper_bound!(m, ramp_limits_startup)
end

@doc raw"""
Sets an upper bound on the non-spinning reserve provided by a [unit](@ref), based on [ramp\_limits\_shutdown](@ref).
The constraint is generated for the same unit flows as the
[lower bound on non-spinning reserves](@ref constraint_non_spinning_reserves_lower_bound):

```math
\begin{aligned}
& \sum_{n \in ng: \, p^{is\_non\_spinning}_{(n)}} v^{unit\_flow}_{(u,n,d,s,t)} \\
& \leq p^{ramp\_limits\_shutdown}_{(u,ng,d,s,t)} \cdot p^{capacity\_per\_unit}_{(u,ng,d,s,t)}
\cdot \sum_{n \in ng} v^{nonspin\_units}_{(u,n,s,t)} \\
& \forall (u,ng,d) \in indices(p^{capacity\_per\_unit}): \exists n \in ng: p^{reserve\_active}_{(n)} \land p^{is\_non\_spinning}_{(n)} \\
& \forall (s,t)
\end{aligned}
```

where ``v^{nonspin\_units}`` is [nonspin\_units\_started\_up](@ref var_nonspin_units_started_up)
for flows to a node (``d = to\_node``) and [nonspin\_units\_shut\_down](@ref var_nonspin_units_shut_down)
for flows from a node (``d = from\_node``).
The formulation is shown for a single time resolution; with different resolutions,
both sides are weighted by the time-slice durations.
If [ramp\_limits\_shutdown](@ref) is not defined, it defaults to 1, i.e. the full capacity of the units.

See also
[is\_non\_spinning](@ref),
[ramp\_limits\_shutdown](@ref)
"""
function add_constraint_non_spinning_reserves_shut_down_upper_bound!(m::Model)
    _add_constraint_non_spinning_reserves_upper_bound!(m, ramp_limits_shutdown)
end

function _add_constraint_non_spinning_reserves_upper_bound!(m::Model, limit::Parameter)
    name = Dict(
        ramp_limits_startup => :non_spinning_reserves_start_up_upper_bound,
        ramp_limits_shutdown => :non_spinning_reserves_shut_down_upper_bound,
    )[limit]
    _add_constraint!(
        m,
        name,
        constraint_non_spinning_reserves_bounds_indices,
        (m, ind...) -> _build_constraint_non_spinning_reserves_upper_bound(m, ind..., limit),
    )
end

function _build_constraint_non_spinning_reserves_upper_bound(m::Model, u, ng, d, s_path, t, limit::Parameter)
    @fetch unit_flow, nonspin_units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    @build_constraint(
        sum(
            unit_flow[u, n, d, s, t_short] * duration(t_short)
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_in_t(m; t_long=t)
            )
            if reserve_active(node=n) && is_non_spinning(node=n);
            init=0,
        )
        <=
        sum(
            + limit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_over, _default=1)
            * capacity_per_unit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_over)
            * _switch(d; from_node=nonspin_units_shut_down, to_node=nonspin_units_started_up)[u, n, s, t_over]
            * min(duration(t), duration(t_over))
            for (u, n, s, t_over) in _switch(
                d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices
            )(m; unit=u, node=ng, stochastic_scenario=s_path, t=t_overlaps_t(m; t));
            init=0,
        )
    )
end

function constraint_non_spinning_reserves_bounds_indices(m::Model)
    (
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(capacity_per_unit)
        if any(reserve_active(node=n) && is_non_spinning(node=n) for n in members(ng))
        for (t, path) in t_lowest_resolution_path(
            m,
            unit_flow_indices(m; unit=u, node=ng, direction=d),
            _switch(d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices)(m; unit=u)
        )
    )
end

"""
    constraint_non_spinning_reserves_bounds_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:non_spinning_units_started_up_bounds` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`unit_flow` and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_non_spinning_reserves_bounds_indices_filtered(
    m::Model; unit=anything, node=anything, direction=anything, stochastic_path=anything, t=anything
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_non_spinning_units_started_up_bounds_indices(m))
end
