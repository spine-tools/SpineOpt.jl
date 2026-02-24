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
This is a generic data-driven custom constraint
which allows for defining constraints involving multiple [unit](@ref)s, [node](@ref)s, or [connection](@ref)s.
The [constraint\_sense](@ref) parameter changes the sense of the [user\_constraint](@ref),
while the [right\_hand\_side](@ref) parameter allows for defining the constant term of the constraint.

Coefficients for the different [variables](@ref Variables) appearing in the [user\_constraint](@ref) are defined
using relationships, like e.g. [unit\_\_from\_node\_\_user\_constraint](@ref) and
[connection\_\_to\_node\_\_user\_constraint](@ref) for [unit\_flow](@ref) and [connection\_flow](@ref) variables,
or [unit\_\_user\_constraint](@ref) and [node\_\_user\_constraint](@ref) for [units\_on](@ref), [units\_started\_up](@ref),
and [node_state](@ref) variables.

For more information, see the dedicated article on [User Constraints](@ref)

```math
\begin{aligned}
& \sum_{u, n} \left\{
  \begin{aligned}     
       & \sum_{op=1}^{\left\| p^{operating\_points}_{(u)} \right\|} p^{unit\_flow\_coefficient}_{(u,n,op,uc,s,t)}
       \cdot v^{unit\_flow\_op}_{(u,n,d,op,s,t)} &\text{if } \left\| p^{operating\_points}_{(u)} \right\| > 1 & \\
       & p^{unit\_flow\_coefficient}_{(u,n,uc,s,t)} \cdot v^{unit\_flow}_{(u,n,d,s,t)} &\text{otherwise} & \\       
  \end{aligned}
  \right.
\\
&+\sum_{u} p^{units\_started\_up\_coefficient}_{(u,uc,s,t)} \cdot v^{units\_started\_up}_{(u,s,t)} \\
&+\sum_{u} p^{units\_on\_coefficient}_{(u,uc,s,t)} \cdot v^{units\_on}_{(u,s,t)} \\
&+\sum_{c} p^{connection\_flow\_coefficient}_{(c,n,uc,s,t)} \cdot v^{connection\_flow}_{(c,n,d,s,t)} \\
&+\sum_{n} p^{node\_state\_coefficient}_{(n,uc,s,t)} \cdot v^{node\_state}_{(n,s,t)} \\
&+\sum_{n} p^{demand\_coefficient}_{(n,uc,s,t)} \cdot p^{demand}_{(n,s,t)} \\
& \begin{cases}  
       = &\text{if } p^{constraint\_sense}_{(uc)} \text{= "=="}\\
       \geq &\text{if } p^{constraint\_sense}_{(uc)} \text{= ">="}\\
       \leq &\text{if } p^{constraint\_sense}_{(uc)} \text{= "=="}\\
  \end{cases}\\
&+p^{right\_hand\_side}_{(uc,t,s)}\\
&\forall uc \in user\_constraint \\
&\forall (s,t)
\end{aligned}
```
"""
function add_constraint_user_constraint!(m::Model)
    _add_constraint!(m, :user_constraint, constraint_user_constraint_indices, _build_constraint_user_constraint)
end

function _build_constraint_user_constraint(m::Model, uc, path, t)
    build_sense_constraint(
        + _operations_term(m, uc, path, t)
        + _investment_term(m, uc, path, t),
        constraint_sense(user_constraint=uc),
        + sum(right_hand_side(m; user_constraint=uc, stochastic_scenario=s, t=t) for s in path; init=0)
        * duration(t)
        / length(path),
    )
end

function _operations_term(m, uc, path, t)
    @fetch (
        unit_flow_op,
        unit_flow,
        units_on,
        units_started_up,
        connection_flow,
        node_state,
        user_constraint_slack_pos,
        user_constraint_slack_neg
    ) = m.ext[:spineopt].variables
    in_t = setdiff(t_in_t(m; t_long=t), history_time_slice(m))
    overlaps_t = setdiff(t_overlaps_t(m; t=t), history_time_slice(m))
    (
        + sum(
            + unit_flow_op[u, n, d, op, s, t_short]
            * unit_flow_coefficient(
                m; unit=u, node=n, user_constraint=uc, direction=d, i=op, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (u, n) in unit__from_node__user_constraint(user_constraint=uc, direction=direction(:from_node))
            for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                m; unit=u, node=n, direction=direction(:from_node), stochastic_scenario=path, t=in_t
            );
            init=0,
        )
        + sum(
            + unit_flow[u, n, d, s, t_short]
            * unit_flow_coefficient(
                m; unit=u, node=n, user_constraint=uc, direction=d, i=1, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (u, n) in unit__from_node__user_constraint(user_constraint=uc, direction=direction(:from_node))
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=n, direction=direction(:from_node), stochastic_scenario=path, t=in_t
            )
            if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
            init=0,
        )
        + sum(
            + unit_flow_op[u, n, d, op, s, t_short]
            * unit_flow_coefficient(
                m; unit=u, node=n, user_constraint=uc, direction=d, i=op, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (u, n) in unit__to_node__user_constraint(user_constraint=uc, direction=direction(:to_node))
            for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                m; unit=u, node=n, direction=direction(:to_node), stochastic_scenario=path, t=in_t
            );
            init=0,
        )
        + sum(
            + unit_flow[u, n, d, s, t_short]
            * unit_flow_coefficient(
                m; unit=u, node=n, user_constraint=uc, direction=d, i=1, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (u, n) in unit__to_node__user_constraint(user_constraint=uc, direction=direction(:to_node))
            for (u, n, d, s, t_short) in unit_flow_indices(
                m; unit=u, node=n, direction=direction(:to_node), stochastic_scenario=path, t=in_t
            )
            if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
            init=0,
        )
        + sum(
            + units_on[u, s, t1]
            * units_on_coefficient(m; user_constraint=uc, unit=u, stochastic_scenario=s, t=t1)
            * min(duration(t1), duration(t))
            for u in unit__user_constraint(user_constraint=uc)
            for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=path, t=overlaps_t);
            init=0,
        )
        + sum(
            + units_started_up[u, s, t1]
            * units_started_up_coefficient(m; user_constraint=uc, unit=u, stochastic_scenario=s, t=t1)
            * min(duration(t1), duration(t))
            for u in unit__user_constraint(user_constraint=uc)
            for (u, s, t1) in units_switched_indices(m; unit=u, stochastic_scenario=path, t=overlaps_t);
            init=0,
        )
        + sum(
            + connection_flow[c, n, d, s, t_short]
            * connection_flow_coefficient(
                m; connection=c, node=n, user_constraint=uc, direction=d, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (c, n) in connection__from_node__user_constraint(
                user_constraint=uc, direction=direction(:from_node)
            )
            for (c, n, d, s, t_short) in connection_flow_indices(
                m; connection=c, node=n, direction=direction(:from_node), stochastic_scenario=path, t=in_t
            );
            init=0,
        )
        + sum(
            + connection_flow[c, n, d, s, t_short]
            * connection_flow_coefficient(
                m; connection=c, node=n, user_constraint=uc, direction=d, stochastic_scenario=s, t=t_short
            )
            * duration(t_short)
            for (c, n) in connection__to_node__user_constraint(user_constraint=uc, direction=direction(:to_node))
            for (c, n, d, s, t_short) in connection_flow_indices(
                m; connection=c, node=n, direction=direction(:to_node), stochastic_scenario=path, t=in_t
            );
            init=0,
        )
        + sum(
            + node_state[n, s, t_short]
            * node_state_coefficient(m; node=n, user_constraint=uc, stochastic_scenario=s, t=t_short)
            * duration(t_short)
            for n in indices(node_state_coefficient; user_constraint=uc)
            for (n, s, t_short) in node_state_indices(m; node=n, stochastic_scenario=path, t=in_t);
            init=0,
        )
        + sum(
            + demand(m; node=n, stochastic_scenario=s, t=t)
            * demand_coefficient(m; node=n, user_constraint=uc, stochastic_scenario=s, t=t)
            * duration(t_short)
            for n in node__user_constraint(user_constraint=uc)
            for (ns, s, t_short) in node_stochastic_time_indices(m; node=n, stochastic_scenario=path, t=in_t);
            init=0,
        )
        + sum(
            user_constraint_slack_pos[uc, s, t] - user_constraint_slack_neg[uc, s, t]
            for (uc, s, t) in user_constraint_slack_indices(m; user_constraint=uc, stochastic_scenario=path, t=t);
            init=0,
        )
    )
end

function _investment_term(m, uc, path, t)
    @fetch (
        units_invested,
        units_invested_available,
        storages_invested,
        storages_invested_available,
        connections_invested,
        connections_invested_available,
    ) = m.ext[:spineopt].variables
    overlaps_t = setdiff(t_overlaps_t(m; t=t), history_time_slice(m))
    (
        + sum(
            (
                + units_invested_available[u, s, t1]
                * units_invested_available_coefficient(m; user_constraint=uc, unit=u, stochastic_scenario=s, t=t1)
                + units_invested[u, s, t1]
                * units_invested_coefficient(m; user_constraint=uc, unit=u, stochastic_scenario=s, t=t1)
            )
            * min(duration(t1), duration(t))
            for u in unit__user_constraint(user_constraint=uc)
            for (u, s, t1) in units_invested_available_indices(m; unit=u, stochastic_scenario=path, t=overlaps_t);
            init=0,
        )
        + sum(
            (
                + connections_invested_available[c, s, t1]
                * connections_invested_available_coefficient(
                    m; user_constraint=uc, connection=c, stochastic_scenario=s, t=t1
                )
                + connections_invested[c, s, t1]
                * connections_invested_coefficient(m; user_constraint=uc, connection=c, stochastic_scenario=s, t=t1)
            )
            * min(duration(t1), duration(t))
            for c in connection__user_constraint(user_constraint=uc)
            for (c, s, t1) in connections_invested_available_indices(
                m; connection=c, stochastic_scenario=path, t=overlaps_t
            );
            init=0,
        )
        + sum(
            (
                + storages_invested_available[n, s, t1]
                * storages_invested_available_coefficient(m; user_constraint=uc, node=n, stochastic_scenario=s, t=t1)
                + storages_invested[n, s, t1]
                * storages_invested_coefficient(m; user_constraint=uc, node=n, stochastic_scenario=s, t=t1)
            )
            * min(duration(t1), duration(t))
            for n in node__user_constraint(user_constraint=uc)
            for (n, s, t1) in storages_invested_available_indices(m; node=n, stochastic_scenario=path, t=overlaps_t);
            init=0,
        )
    )
end

function constraint_user_constraint_indices(m::Model)
    (
        (user_constraint=uc, stochastic_path=path, t=t)
        for uc in user_constraint()
        for (t, path) in t_lowest_resolution_path(
            m, Iterators.flatten(user_constraint_all_indices(m; user_constraint=uc))
        )
        if _is_representative(t) || include_in_non_representative_periods(user_constraint=uc)
    )
end

"""
    constraint_user_constraint_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:user_constraint` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow`, `unit_flow_op`,
and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_user_constraint_indices_filtered(
    m::Model;
    user_constraint=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; user_constraint=user_constraint, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_user_constraint_indices(m))
end

function user_constraint_all_indices(
        m::Model; user_constraint=anything, stochastic_scenario=anything, t=anything, temporal_block=anything
    )
    (
        _user_constraint_unit_flow_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_units_on_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_connection_flow_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_node_state_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_node_stochastic_time_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_units_invested_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_connections_invested_indices(m, user_constraint, stochastic_scenario, t, temporal_block),
        _user_constraint_storages_invested_indices(m, user_constraint, stochastic_scenario, t, temporal_block)
    )
end

function _user_constraint_unit_flow_indices(m, uc, s, t, tb)
    (
        ind
        for (unit__node__user_constraint, d) in (
            (unit__from_node__user_constraint, :from_node), (unit__to_node__user_constraint, :to_node)
        )
        for (u, n) in unit__node__user_constraint(user_constraint=uc)
        for ind in unit_flow_indices(
            m; unit=u, node=n, direction=direction(d), stochastic_scenario=s, t=t, temporal_block=tb
        )
    )
end

function _user_constraint_units_on_indices(m, uc, s, t, tb)
    (
        ind
        for u in unit__user_constraint(user_constraint=uc)
        for ind in units_on_indices(m; unit=u, stochastic_scenario=s, t=t, temporal_block=tb)
    )
end

function _user_constraint_connection_flow_indices(m, uc, s, t, tb)
    (
        ind
        for (connection__node__user_constraint, d) in (
            (connection__from_node__user_constraint, :from_node), (connection__to_node__user_constraint, :to_node)
        )
        for (c, n) in connection__node__user_constraint(user_constraint=uc)
        for ind in connection_flow_indices(
            m; connection=c, node=n, direction=direction(d), stochastic_scenario=s, t=t, temporal_block=tb
        )
    )
end

function _user_constraint_node_state_indices(m, uc, s, t, tb)
    (
        ind
        for n in node__user_constraint(user_constraint=uc)
        for ind in node_state_indices(m; node=n, stochastic_scenario=s, t=t, temporal_block=tb)
    )
end

function _user_constraint_units_invested_indices(m, uc, s, t, tb)
    (
        ind
        for u in unit__user_constraint(user_constraint=uc)
        for ind in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t, temporal_block=tb)
    )
end

function _user_constraint_connections_invested_indices(m, uc, s, t, tb)
    (
        ind
        for c in connection__user_constraint(user_constraint=uc)
        for ind in connections_invested_available_indices(
            m; connection=c, stochastic_scenario=s, t=t, temporal_block=tb
        )
    )
end

function _user_constraint_storages_invested_indices(m, uc, s, t, tb)
    (
        ind
        for n in node__user_constraint(user_constraint=uc)
        for ind in storages_invested_available_indices(m; node=n, stochastic_scenario=s, t=t, temporal_block=tb)
    )
end

function _user_constraint_node_stochastic_time_indices(m, uc, s, t, tb)
    (
        ind
        for n in node__user_constraint(user_constraint=uc)
        for ind in node_stochastic_time_indices(m; node=n, stochastic_scenario=s, t=t, temporal_block=tb)
    )
end
