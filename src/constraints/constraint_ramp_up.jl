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
#COPY from unit_state_transition"

"""
    constraint_ramp_up_indices()

Form the stochastic index set for the `:ramp_up` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
"""
function constraint_ramp_up_indices()
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(ramp_up_limit)
        for t in t_lowest_resolution(t for t in time_slice(temporal_block=node__temporal_block(node=expand_node_group(ng))))
        # How to deal with groups correctly?
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in Iterators.flatten(
                    (units_on_indices(
                    unit=u, t=t),
                    ramp_up_unit_flow_indices(
                    unit=u, node=ng, direction=d, t=t_before_t(t_after=t))
                    )
                )  # Current `units_on` and `units_available`, plus `units_shut_down` during past time slices
            )
        )
    )
end

"""
    add_constraint_ramp_up!(m::Model)

Limit the maximum ramp of `ramp_up_unit_flow` of a `unit` or `unit_group` if the parameters
`ramp_up_limit`,`unit_capacity`,`unit_conv_cap_to_unit_flow` exist.
"""
function add_constraint_ramp_up!(m::Model)
    @fetch units_on,  units_started_up, ramp_up_unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:ramp_up] = Dict()
    for (u, ng, d, s, t) in constraint_ramp_up_indices()
        constr_dict[u, ng, d, s, t] = @constraint(
            m,
            + sum(
                ramp_up_unit_flow[u, n, d, s, t]
                        for (u, n, d, s, t) in ramp_up_unit_flow_indices(
                            unit=u, node=ng, direction = d, t=t, stochastic_scenario=s)
            )
            <=
            + sum(
                units_on[u, s, t] - units_started_up[u, s, t]
                    for (u,s,t) in units_on_indices(
                        unit=u, stochastic_scenario=s, t=t_overlaps_t(t)
                            )
                )
                 * ramp_up_limit[(unit=u, node=ng, direction=d, t=t, stochastic_scenario=s)]
                    *unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, t=t, stochastic_scenario=s)]
                        *unit_capacity[(unit=u, node=ng, direction=d, t=t, stochastic_scenario=s)]
        )
    end
end
