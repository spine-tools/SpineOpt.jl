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
    constraint_unit_flow_capacity_indices()

Forms the stochastic index set for the `:unit_flow_capacity` constraint.

Uses stochastic path indices due to potentially different stochastic structures
between `unit_flow` and `units_on` variables.
"""
function constraint_unit_flow_capacity_indices(m)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity)
        for t in time_slice(m; temporal_block=node__temporal_block(node=members(ng)))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_unit_flow_capacity_indices(m, u, ng, d, t))
        )
    )
end

"""
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.

Check if `unit_conv_cap_to_flow` is defined.
"""
#TODO: How can we support both unit_capacity w/o start ramps
#TODO: At the moment this is only valid for units with MUT >= 2
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on, units_started_up, units_shut_down = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:unit_flow_capacity] = Dict(
        (u, ng, d, s, t) => @constraint(
            m,
            expr_sum(
                + unit_flow[u, n, d, s, t]
                for (u, n, d, s, t) in setdiff(
                    unit_flow_indices(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t),
                    nonspin_ramp_up_unit_flow_indices(
                        m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t
                    )
                );
                init=0
            )
            * duration(t)
            <=
            + expr_sum(
                (units_on[u, s, t1] - units_started_up[u, s, t1] - units_shut_down[u, s, t2]) * min(duration(t1), duration(t))
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t))
                    for (u, s, t2) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t1));
                init=0
            )
            + expr_sum(
                units_started_up[u, s, t1] * min(duration(t1), duration(t))
                * max_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                    init=0
            )
            + expr_sum(
                units_shut_down[u, s, t2] * min(duration(t2), duration(t))
                * max_shutdown_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t2) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t));
                init=0
            )
        )
        for (u, ng, d, s, t) in constraint_unit_flow_capacity_indices(m)
    )
end
