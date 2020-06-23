#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
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

"""
    constraint_max_nonspin_ramp_up_indices()

Form the stochastic index set for the `:max_nonspin_start_up_ramp` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""
function constraint_max_nonspin_ramp_up_indices()
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(max_res_startup_ramp)
        for t in time_slice(temporal_block=node__temporal_block(node=expand_node_group(ng)))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in Iterators.flatten(
            (nonspin_ramp_up_unit_flow_indices(
                unit=u,
                node=ng,
                direction=d,
                t=t),
            nonspin_starting_up_indices(
                unit=u,
                node=ng,
                t=t)))
            )
        )
    )
end

"""
    add_constraint_max_nonspin_start_up_ramp!(m::Model)

Limit the maximum ramp at the start up of a unit.

For reserves the max non-spinning reserve ramp can be defined here.
"""
function add_constraint_max_nonspin_ramp_up!(m::Model)
    @fetch nonspin_ramp_up_unit_flow, nonspin_starting_up = m.ext[:variables]
    cons = m.ext[:constraints][:max_nonspin_start_up_ramp] = Dict()
    for (u, ng, d, s_path, t) in constraint_max_nonspin_ramp_up_indices()
        cons[u, ng, d, s_path, t] = @constraint(
            m,
            + sum(
                nonspin_ramp_up_unit_flow[u, n, d, s, t]
                        for (u, n, d, s, t) in nonspin_ramp_up_unit_flow_indices(
                            unit=u, node=ng, direction=d, stochastic_scenario=s_path, t=t_in_t(t_long=t))
            )
            <=
            + expr_sum(
                nonspin_starting_up[u, n, s, t]
                * max_res_startup_ramp[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)]
                * unit_capacity[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)]
                        for (u, n, s, t) in nonspin_starting_up_indices(
                            unit=u, node=ng, stochastic_scenario=s_path, t=t_overlaps_t(t));
                            init=0
            )

        )
    end
end
