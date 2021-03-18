#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    @fetch node_injection, node_state, unit_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    # TODO: We need to include both: storages that are defined on n and storage that are defined on internal nodes
    m.ext[:constraints][:node_injection] = Dict(
        (node=n, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            +expr_sum(
                + node_injection[n, s, t_after]
                + demand[(node=n,
                        stochastic_scenario=s,
                        analysis_time=t0,
                        t=
                        (!isempty(indices(representative_periods_mapping)) ? representative_time_slices(m)[to_time_slice(m,t=t_after)] : t))]
                for (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s, t=t_after, temporal_block=anything);
                init=0,
            ) + expr_sum(
                fractional_demand[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_after)] *
                demand[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for (n, s, t) in node_injection_indices(m; node=n, stochastic_scenario=s, t=t_after, temporal_block=anything)
                for ng in groups(n);
                init=0,
            ) ==
            +expr_sum(
                (
                    +get(node_state, (n, s, t_before), 0) *
                    state_coeff[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_before)] -
                    get(node_state, (n, s, t_after), 0) *
                    state_coeff[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                ) / duration(t_after)
                # Self-discharge commodity losses
                -
                get(node_state, (n, s, t_after), 0) *
                frac_state_loss[(node=n, stochastic_scenario=s, analysis_time=t0, t=t_after)] for s in s;
                init=0,
            )
            # Diffusion of commodity from other nodes to this one
            +
            expr_sum(
                get(node_state, (other_node, s, t_after), 0) *
                diff_coeff[(node1=other_node, node2=n, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node2=n) for s in s;
                init=0,
            )
            # Diffusion of commodity from this node to other nodes
            -
            expr_sum(
                get(node_state, (n, s, t_after), 0) *
                diff_coeff[(node1=n, node2=other_node, stochastic_scenario=s, analysis_time=t0, t=t_after)]
                for other_node in node__node(node1=n) for s in s;
                init=0,
            )
            # Commodity flows from units
            +
            expr_sum(
                unit_flow[u, n, d, s, t_short]
                for
                (u, n, d, s, t_short) in unit_flow_indices(
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
            -
            expr_sum(
                unit_flow[u, n, d, s, t_short]
                for
                (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t_after),
                    temporal_block=anything,
                );
                init=0,
            )
        ) for (n, s, t_before, t_after) in constraint_node_injection_indices(m)
    )
end

#TODO: can we find an easier way to define the constraint indices?
# I feel that for unexperienced uses it gets more an more complicated to understand our code
"""
    constraint_node_injection_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:node_injection` constraint.

Uses stochastic path indices due to dynamics and potentially different stochastic structures between this
`node` and `nodes` connected via diffusion. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_node_injection_indices(
    m::Model;
    node=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    unique(
        (node=n, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (n, t_before, t_after) in node_dynamic_time_indices(m; node=node)
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_node_injection_indices(m, n, t_after, t_before)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_node_injection_indices(m, node, t_after, t_before)

Gather the current `node_stochastic_time_indices` as well as the relevant `node_state_indices` on the previous
`time_slice` and beyond defined `node__node` relationships for `add_constraint_node_injection!`
"""
function _constraint_node_injection_indices(m, node, t_after, t_before)
    Iterators.flatten((
        # `node` on `t_after`, this needs to be included regardless of whether the `node` has a `node_state`
        node_stochastic_time_indices(m; node=node, t=t_after),
        # `node_state` on `t_before`
        node_state_indices(m; node=node, t=t_before),
        # Diffusion to this `node`
        (ind for n1 in node__node(node2=node) for ind in node_state_indices(m; node=n1, t=t_after)),
        # Diffusion from this `node`
        (ind for n2 in node__node(node1=node) for ind in node_state_indices(m; node=n2, t=t_after)),
    ))
end
