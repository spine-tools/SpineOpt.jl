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
    constraint_split_ramps_indices()

Forms the stochastic index set for the `:split_ramps` constraint.
Uses stochastic path indices due to potentially different stochastic scenarios
between `t_after` and `t_before`.
"""

function constraint_split_ramps_indices()
    unique(
        (unit=u, node=n, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, n, d, s, t_after) in unique(Iterators.flatten(
                (ramp_up_unit_flow_indices(),
                    start_up_unit_flow_indices(),
                        nonspin_ramp_up_unit_flow_indices())
                        )
                        )
        for (u, n, d, s, t_before) in unit_flow_indices(unit=u,node=n,direction=d,t=t_before_t(t_after=t_after))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in unit_flow_indices(unit=u, node=n, direction=d, t=[t_before, t_after]))
        )
    )
end
"""
    add_constraint_split_ramps!(m::Model)

Split delta(`unit_flow`) in `ramp_up_unit_flow and` `start_up_unit_flow`. This is
required to enforce separate limitations on these two ramp types.
"""
function add_constraint_split_ramps!(m::Model)
    @fetch unit_flow, ramp_up_unit_flow, start_up_unit_flow, nonspin_ramp_up_unit_flow = m.ext[:variables]
    #TODO: ask Topi how this one would be properly done with stochastics
    constr_dict = m.ext[:constraints][:split_ramp_up] = Dict()
    for (u, n, d, s_path, t_before, t_after) in constraint_split_ramps_indices()
        constr_dict[u, n, d, s_path,t_before, t_after] = @constraint(
            m,
            expr_sum(
            + unit_flow[u, n, d, s, t_after]
                for (u, n, d, s, t_after) in unit_flow_indices(
                    unit=u,node=n,direction=d,stochastic_scenario=s_path,t=t_after
                    );
                    init=0
            )
            -
            expr_sum(
            + unit_flow[u, n, d, s, t_before]
                for (u, n, d, s, t_before) in unit_flow_indices(
                    unit=u,node=n,direction=d,stochastic_scenario=s_path,t=t_before
                    )
                if is_reserve_node(node=n) == :is_reserve_node_false;
                    init=0
            )
            <=
            expr_sum(
            get(ramp_up_unit_flow,(u, n, d, s, t_after),0)
            +
            get(start_up_unit_flow,(u, n, d, s, t_after),0)
            +
            get(nonspin_ramp_up_unit_flow,(u, n, d, s, t_after),0)
            for s in s_path;
                init=0)
        )
    end
end
