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
    constraint_minimum_operating_point_indices()

Form the stochastic index set for the `:minimum_operating_point` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`unit_flow` and `units_on` variables.
"""
function constraint_minimum_operating_point_indices()
    unique(
        (unit=u, node=n, direction=d, stochastic_path=path, t=t)
        for (u, n, d) in indices(minimum_operating_point)
        for t in time_slice(temporal_block=node__temporal_block(node=n))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_unit_flow_capacity_indices(u, n, d, t))
        )
    )
end

"""
    add_constraint_minimum_operating_point!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, unit_availability_factor` exist.
"""
function add_constraint_minimum_operating_point!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    t0 = start(current_window)
    m.ext[:constraints][:minimum_operating_point] = Dict(
        (u, ng, d, s, t) => @constraint(
            m,
            + expr_sum(
                + unit_flow[u, n, d, s, t]
                for (u, n, d, s, t) in unit_flow_indices(
                    unit=u, node=ng, direction=d, stochastic_scenario=s, t=t
                );
                init=0
            )
            * duration(t)
            >=
            + expr_sum(
                + units_on[u, s, t1] * min(duration(t), duration(t1))
                * minimum_operating_point[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(
                    unit=u, stochastic_scenario=s, t=t_overlaps_t(t)
                );
                init=0
            )
        )
        for (u, ng, d, s, t) in constraint_minimum_operating_point_indices()
    )
end
