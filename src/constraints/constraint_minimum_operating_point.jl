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
            # Current `unit_flow`
            active_scenarios = unit_flow_indices_rc(
                unit=u, node=n, direction=d, t=t, _compact=true
            )
            # Current `units_on`
            append!(
                active_scenarios,
                units_on_indices_rc(unit=u, t=t_in_t(t_short=t), compact=true)
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
    for (u, n, d, stochastic_path, t) in constraint_minimum_operating_point_indices()
        cons[u, n, d, stochastic_path, t] = @constraint(
            m,
            reduce(+, get(unit_flow, (u, n, d, s, t), 0) for s in stochastic_path; init=0)
            >=
            reduce(
                +,
                units_on[u, s, t]
                * minimum_operating_point[(unit=u, node=n, direction=d, t=t)] # TODO: Stochastic parameters
                * unit_capacity[(unit=u, node=n, direction=d, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
                for (u, s, t) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_in_t(t_short=t)
                );
                init=0
            )
        )
    end
end