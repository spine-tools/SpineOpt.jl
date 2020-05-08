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
    constraint_unit_state_transition_indices()

Forms the stochastic index set for the `:unit_state_transition` constraint.
Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""
function constraint_unit_state_transition_indices()
    unit_state_transition_indices = []
    for (u, n) in unit__structure_node_rc()
        for t_after in time_slice(temporal_block=node__temporal_block(node=n))
            # `units_on` on `t_after`
            active_scenarios = units_on_indices_rc(unit=u, t=t_after, _compact=true)
            # `units_on` on `t_before`
            t_before = first(t_before_t(t_after=t_after))
            append!(
                active_scenarios,
                units_on_indices_rc(unit=u, t=t_before, _compact=true)
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    unit_state_transition_indices,
                    (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
                )
            end
        end
    end
    return unique!(unit_state_transition_indices)
end


"""
    add_constraint_unit_state_transition!(m::Model)

This constraint ensures consistency between the variables `units_on`, `units_started_up`
and `units_shut_down`.
"""
function add_constraint_unit_state_transition!(m::Model)
    @fetch units_on, units_started_up, units_shut_down = m.ext[:variables]
    cons = m.ext[:constraints][:unit_state_transition] = Dict()
    for (u, stochastic_path, t_before, t_after) in constraint_unit_state_transition_indices()
        cons[u, stochastic_path, t_before, t_after] = @constraint(
            m,
            expr_sum(
                + units_on[u, s, t_after]
                - units_started_up[u, s, t_after]
                + units_shut_down[u, s, t_after]
                for (u, s, t_after) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_after
                );
                init=0
            )
            ==
            expr_sum(
                + units_on[u, s, t_before]
                for (u, s, t_before) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_before
                );
                init=0
            )
        )
    end
end