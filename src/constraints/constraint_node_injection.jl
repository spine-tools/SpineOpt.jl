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
The node injection itself represents all local production and consumption,
computed as the sum of all connected unit flows and the nodal demand.
If a node corresponds to a storage node, the parameter [has\_state](@ref)
should be set to [true](@ref boolean_value_list) for this node.
The node injection is created for each node in the network
(unless the node is only used for parameter aggregation purposes, see [Introduction to groups of objects](@ref)).

```math
\begin{aligned}
& v^{node\_injection}_{(n,s,t)} \\
& = \\
& \left(p^{state\_coeff}_{(n, s, t-1)} \cdot v^{node\_state}_{(n, s, t-1)} - p^{state\_coeff}_{(n, s, t)} \cdot v^{node\_state}_{(n, s, t)}\right)
/ \Delta t \\
& - p^{frac\_state\_loss}_{(n,s,t)} \cdot v^{node\_state}_{(n, s, t)} \\
& + \sum_{n'} p^{diff\_coeff}_{(n',n,s,t)} \cdot v^{node\_state}_{(n', s, t)}
- \sum_{n'} p^{diff\_coeff}_{(n,n',s,t)} \cdot v^{node\_state}_{(n, s, t)} \\
& + \sum_{
        u
}
v^{unit\_flow}_{(u,n,to\_node,s,t)}
- \sum_{
        u
}
v^{unit\_flow}_{(u,n,from\_node,s,t)}\\
& - \left(p^{demand}_{(n,s,t)} + \sum_{ng \ni n} p^{fractional\_demand}_{(n,s,t)} \cdot p^{demand}_{(ng,s,t)}\right) \\
& + v^{node\_slack\_pos}_{(n,s,t)} - v^{node\_slack\_neg}_{(n,s,t)} \\
& \forall n \in node: p^{has\_state}_{(n)}\\
& \forall (s, t)
\end{aligned}
```

See also
[state\_coeff](@ref),
[frac\_state\_loss](@ref),
[diff\_coeff](@ref),
[node\_\_node](@ref),
[unit\_\_from\_node](@ref),
[unit\_\_to\_node](@ref),
[demand](@ref),
[fractional\_demand](@ref),
[has\_state](@ref).

"""
function add_constraint_node_injection!(m::Model)
    _add_constraint!(m, :node_injection, constraint_node_injection_indices, _build_constraint_node_injection)
end

function _build_constraint_node_injection(m::Model, n, s_path, t_before, t_after)
    @fetch node_injection, node_state, unit_flow, node_slack_pos, node_slack_neg = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            + node_injection[n, s, t_after]
            + _total_demand(m, n, s, t_after)
            # node slack
            - get(node_slack_pos, (n, s, t_after), 0) + get(node_slack_neg, (n, s, t_after), 0)
            for s in s_path
            if haskey(node_injection, (n, s, t_after));
            init=0,
        )
        ==            
        + sum(
            (
                + get(node_state, (n, s, t_before), 0)
                * state_coeff(m; node=n, stochastic_scenario=s, t=t_before)
                - get(node_state, (n, s, t_after), 0)
                * state_coeff(m; node=n, stochastic_scenario=s, t=t_after)
            ) / duration(t_after)
            # Self-discharge commodity losses
            - get(node_state, (n, s, t_after), 0)
            * frac_state_loss(m; node=n, stochastic_scenario=s, t=t_after)
            for s in s_path;
            init=0,
        )
        # Diffusion of commodity from other nodes to this one
        + sum(
            get(node_state, (other_node, s, t_after), 0)
            * diff_coeff(m; node1=other_node, node2=n, stochastic_scenario=s, t=t_after)
            for other_node in node__node(node2=n)
            for s in s_path;
            init=0,
        )
        # Diffusion of commodity from this node to other nodes
        - sum(
            get(node_state, (n, s, t_after), 0)
            * diff_coeff(m; node1=n, node2=other_node, stochastic_scenario=s, t=t_after)
            for other_node in node__node(node1=n)
            for s in s_path;
            init=0,
        )
        # Commodity flows from units
        + sum(
            get(unit_flow, (u, n1, d, s, t_short), 0)
            for n1 in members(n)
            for (u, d) in unit__to_node(node=n1)
            for s in s_path
            for t_short in t_in_t(m; t_long=t_after);
            init=0,
        )
        # Commodity flows to units
        - sum(
            get(unit_flow, (u, n1, d, s, t_short), 0)
            for n1 in members(n)
            for (u, d) in unit__from_node(node=n1)
            for s in s_path
            for t_short in t_in_t(m; t_long=t_after);
            init=0,
        )
    )
end

function _total_demand(m, n, s, t_after)
    @expression(
        m,
        + sum(demand(m; node=n, stochastic_scenario=s, t=t) * coef for (t, coef) in _repr_t_coefs(m, t_after))
        + sum(
            + sum(
                + fractional_demand(m; node=n, stochastic_scenario=s, t=t)
                * demand(m; node=ng, stochastic_scenario=s, t=t)
                * coef
                for (t, coef) in _repr_t_coefs(m, t_after)
            )
            for ng in groups(n);
            init=0,
        )
    )
end

function constraint_node_injection_indices(m::Model)
    (
        (node=n, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (n, t_before, t_after) in node_dynamic_time_indices(m)
        for path in active_stochastic_paths(
            m,
            Iterators.flatten(
                (
                    node_stochastic_time_indices(m; node=n, t=t_after),
                    node_state_indices(m; node=n, t=t_before),
                    node_state_indices(m; node=[node__node(node2=n); node__node(node1=n)], t=t_after),
                )
            )
        )
    )
end

"""
    constraint_node_injection_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:node_injection` constraint.

Uses stochastic path indices due to dynamics and potentially different stochastic structures between this
`node` and `nodes` connected via diffusion. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_node_injection_indices_filtered(
    m::Model;
    node=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_node_injection_indices(m))
end
