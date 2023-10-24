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

"""
    add_constraint_node_injection!(m::Model)

Set the node injection equal to the summation of all 'input' flows but connection's.
"""
function add_constraint_node_injection!(m::Model)
    @fetch node_injection, node_state, unit_flow, node_slack_pos, node_slack_neg = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    # TODO: We need to include both: storages that are defined on n and storage that are defined on internal nodes
    m.ext[:spineopt].constraints[:node_injection] = Dict(
        (node=n, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + expr_sum(
                + node_injection[n, s, t]
                + demand[
                    (node=n, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t))
                ]
                # node slack
                - get(node_slack_pos, (n, s, t), 0) + get(node_slack_neg, (n, s, t), 0)
                for (n, s, t) in node_injection_indices(
                    m; node=n, stochastic_scenario=s, t=t_after, temporal_block=anything
                );
                init=0,
            )
            + expr_sum(
                fractional_demand[(node=n, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t))]
                * demand[(node=ng, stochastic_scenario=s, analysis_time=t0, t=representative_time_slice(m, t))]
                for (n, s, t) in node_injection_indices(
                    m; node=n, stochastic_scenario=s, t=t_after, temporal_block=anything
                )
                for ng in groups(n);
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
                for s in s;
                init=0,
            )
            # Diffusion of commodity from other nodes to this one
            + expr_sum(
                get(node_state, (other_node, s, t_after), 0)
                * diff_coeff[(node1=other_node, node2=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node2=n) for s in s;
                init=0,
            )
            # Diffusion of commodity from this node to other nodes
            - expr_sum(
                get(node_state, (n, s, t_after), 0)
                * diff_coeff[(node1=n, node2=other_node, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node1=n) for s in s;
                init=0,
            )
            # Commodity flows from units
            + expr_sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t_after),
                    temporal_block=anything,
                );
                init=0,
            )
            # Commodity flows to units
            - expr_sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t_after),
                    temporal_block=anything,
                );
                init=0,
            )
        )
        for (n, s, t_before, t_after) in constraint_node_injection_indices(m)
    )
end

# TODO: can we find an easier way to define the constraint indices?
# I feel that for unexperienced uses it gets more an more complicated to understand our code
function constraint_node_injection_indices(m::Model)
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