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
    constraint_minimum_operating_point_indices()

Forms the stochastic index set for the `:minimum_operating_point` constraint.
Uses stochastic path indices due to potentially different stochastic structures
between `unit_flow` and `units_on` variables.
"""
function constraint_minimum_operating_point_indices()
    minimum_operating_point_indices = []
    for (u, n, d) in indices(minimum_operating_point)
        if !in((unit=u, node=n, direction=d), indices(unit_capacity))
            error("`unit_capacity` must be defined for `($(u), $(n), $(d))` if `minimum_operating_point` is defined!")
        end
        for t in time_slice(temporal_block=node__temporal_block(node=n))
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # Current `unit_flow`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    unit_flow_indices(
                        unit=u, node=n, direction=d, t=t
                    )
                )
            )
            # Current `units_on`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    units_on_indices(unit=u, t=t_in_t(t_short=t))
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    minimum_operating_point_indices,
                    (unit=u, node=n, direction=d, stochastic_path=path, t=t)
                )
            end
        end
    end
    return unique!(minimum_operating_point_indices)
end


"""
    add_constraint_minimum_operating_point!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, unit_availability_factor` exist.
"""
function add_constraint_minimum_operating_point!(m::Model)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:minimum_operating_point] = Dict()
    for (u, ng, d, stochastic_path, t) in constraint_minimum_operating_point_indices()
        cons[u, ng, d, stochastic_path, t] = @constraint(
            m,
            + expr_sum(
                + unit_flow[u, n, d, s, t]
                for (u, n, d, s, t) in unit_flow_indices(
                    unit=u, node=ng, direction=d, stochastic_scenario=stochastic_path, t=t
                );
                init=0
            )
            * duration(t)
            >=
            + expr_sum(
                + units_on[u, s, t1] * min(duration(t), duration(t1))
                for (u, s, t1) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_overlaps_t(t)
                );
                init=0
            )
            * minimum_operating_point[(unit=u, node=ng, direction=d, t=t)]
            * unit_capacity[(unit=u, node=ng, direction=d, t=t)]
            * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, t=t)]
        )
    end
end
