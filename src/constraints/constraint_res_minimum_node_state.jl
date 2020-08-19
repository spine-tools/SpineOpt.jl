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
    constraint_minimum_node_state_indices()

Form the stochastic index set for the `:minimum_node_state` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`unit_flow` and `units_on` variables.
"""
function constraint_res_minimum_node_state_indices()
    unique(
        (node=n_stor, stochastic_path=path, t=t)
        for (u, n_stor, d, s, t) in unit_flow_indices() if has_state(node=n_stor)
        for (u, n_aFRR, d, s, t) in unit_flow_indices(unit=u,node=collect(indices(minimum_reserve_activation_time)),t=t)
        for path in active_stochastic_paths(
            unique(Iterators.flatten(([ind.stochastic_scenario for ind in node_state_indices(node=n_stor, t=t)],
            [ind.stochastic_scenario for ind in unit_flow_indices(unit=u,node=n_aFRR, direction=d, t=t)]))
        )
        )
    )
end

"""
    add_constraint_res_minimum_node_state!(m::Model)

Limit the `node_state` of a `node` if the parameters `node_state_min,
res_activation_time` exist.
"""
function add_constraint_res_minimum_node_state!(m::Model)
    @fetch unit_flow, node_state = m.ext[:variables]
    t0 = start(current_window)
    m.ext[:constraints][:res_minimum_node_state] = Dict(
        (n_stor, s, t_after) => @constraint(
            m,
            sum(
                node_state[n_stor,s,t_before]
                for (n_stor,s,t_before) in node_state_indices(node=n_stor,stochastic_scenario=s,t=t_before_t(t_after=t_after))
                    )
            >=
            node_state_min[(node=n_stor,stochastic_scenario=s,analysis_time=t0, t=t_after)]
            + expr_sum(
                unit_flow[u,n_res,d,s,t_after]
                * 1/fix_ratio_out_in_unit_flow[(unit=u,node1=n_conv,node2=n_stor,stochastic_scenario=s,analysis_time=t0, t=t_after)]
                * duration(t_after) * (duration(TimeSlice(start(t_after) ,start(t_after) +minimum_reserve_activation_time[(node=n_res,stochastic_scenario=s,analysis_time=t0, t=t_after)].value))/duration(TimeSlice(start(t_after),end_(t_after))))
                    for (u, n_stor, d, s, t_after) in unit_flow_indices(node=n_stor, direction=direction(:from_node),stochastic_scenario=s,t=t_after)
                    for (u, n_res, d, s, t_after) in unit_flow_indices(unit=u,node= collect(indices(minimum_reserve_activation_time)),t=t_after, direction=direction(:to_node))
                    for (u, n_conv, n_stor) in indices(fix_ratio_out_in_unit_flow;unit=u,node2=n_stor) #this only works if only theres only 1 conventional commodity
                        if is_reserve_node(node=n_res) && minimum_reserve_activation_time[(node=n_res,stochastic_scenario=s,analysis_time=t0, t=t_after)].value != nothing; #this is an additional sanity check
                    init=0
            )
        )
        for (n_stor, s, t_after) in constraint_res_minimum_node_state_indices()
    )
end
