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
    @fetch node_injection, node_state, unit_flow, node_slack_pos, node_slack_neg = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    # TODO: We need to include both: storages that are defined on n and storage that are defined on internal nodes
    m.ext[:spineopt].constraints[:node_injection] = Dict(
        (node=n, stochastic_path=s_path, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + expr_sum(
                + node_injection_n_s_t_after
                + demand[
                    (node=n, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t_after))
                ]
                # node slack
                - get(node_slack_pos, (n, s, t_after), 0) + get(node_slack_neg, (n, s, t_after), 0)
                + expr_sum(
                    + fractional_demand[
                        (node=n, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t_after))
                    ]
                    * demand[
                        (node=ng, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t_after))
                    ]
                    for ng in groups(n);
                    init=0,
                )
                for (s, node_injection_n_s_t_after) in (
                    (s, get(node_injection, (n, s, t_after), nothing)) for s in s_path
                )
                if node_injection_n_s_t_after !== nothing;
                init=0,
            )
            ==            
            + expr_sum(
                (
                    + get(node_state, (n, s, t_before), 0)
                    * state_coeff[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_before)]
                    - get(node_state, (n, s, t_after), 0)
                    * state_coeff[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                ) / duration(t_after)
                # Self-discharge commodity losses
                - get(node_state, (n, s, t_after), 0)
                * frac_state_loss[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for s in s_path;
                init=0,
            )
            # Diffusion of commodity from other nodes to this one
            + expr_sum(
                get(node_state, (other_node, s, t_after), 0)
                * diff_coeff[(node1=other_node, node2=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node2=n)
                for s in s_path;
                init=0,
            )
            # Diffusion of commodity from this node to other nodes
            - expr_sum(
                get(node_state, (n, s, t_after), 0)
                * diff_coeff[(node1=n, node2=other_node, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node1=n)
                for s in s_path;
                init=0,
            )
            # Commodity flows from units
            + expr_sum(
                get(unit_flow, (u, n, direction(:to_node), s, t_after), 0)
                for u in unit__to_node(node=n, direction=direction(:to_node))
                for s in s_path;
                init=0,
            )
            # Commodity flows to units
            - expr_sum(
                get(unit_flow, (u, n, direction(:from_node), s, t_after), 0)
                for u in unit__from_node(node=n, direction=direction(:from_node))
                for s in s_path;
                init=0,
            )
        )
        for (n, s_path, t_before, t_after) in constraint_node_injection_indices(m)
    )
end

# TODO: can we find an easier way to define the constraint indices?
# I feel that for unexperienced uses it gets more an more complicated to understand our code
function constraint_node_injection_indices(m::Model)
    flatten(
        select(
            leftjoin(
                leftjoin(
                    node_dynamic_time_indices(m),
                    select!(node_stochastic_time_indices(m), :node, :stochastic_scenario => :s1, :t => :t_after);
                    on=[:node, :t_after],
                ),
                select!(node_state_indices(m), :node, :stochastic_scenario => :s2, :t => :t_before);
                on=[:node, :t_before],
            ),
            :node,
            [:s1, :s2] => ByRow((s1, s2) -> active_stochastic_paths(m, [s1, s2])) => :stochastic_path,
            :t_before,
            :t_after,
        ),
        :stochastic_path,
    )


   #=
    function paths(n, t_before, t_after)
        # return stochastic_scenario()
        active_stochastic_paths(
            m,
            vcat(
                node_stochastic_time_indices(m; node=n, t=t_after),
                node_state_indices(m; node=n, t=t_before),
                node_state_indices(m; node=[node__node(node2=n); node__node(node1=n)], t=t_after)
            )
        )
    end

    flatten(
        select(
            node_dynamic_time_indices(m),
            :node, [:node, :t_before, :t_after] => ByRow(paths) => :stochastic_path, :t_before, :t_after;
            copycols=false,
        ),
        :stochastic_path,
    )
    unique(
        (node=n, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (n, t_before, t_after) in node_dynamic_time_indices(m)
        for path in active_stochastic_paths(
            m,
            vcat(
                node_stochastic_time_indices(m; node=n, t=t_after),
                node_state_indices(m; node=n, t=t_before),
                node_state_indices(m; node=[node__node(node2=n); node__node(node1=n)], t=t_after)
            )
        )
    )
    =#
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