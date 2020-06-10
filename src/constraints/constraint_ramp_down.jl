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

#TODO: stochastic_path
"""
    constraint_ramp_down(m::Model)

Limit the maximum ramp of `flow` of a `unit` if the parameters
`ramp_down_limit,unit_capacity,unit_conv_cap_to_flow, minimum_operating_point` exist.
"""
#TODO: rampdown doens't support downwardreserves yet
#TODO: include later on
function add_constraint_ramp_down!(m::Model)
    @fetch flow, units_on,  units_shut_down, units_started_up = m.ext[:variables]
    constr_dict = m.ext[:constraints][:ramp_down] = Dict()
    for (u, c, d) in intersect(indices(ramp_down_limit),indices(unit_capacity))
        for (u, t_after) in units_on_indices(unit=u)
            for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
                constr_dict[u, c, d, t_after] = @constraint(
                    m,
                    + sum(
                        flow[u_, n, c_, d_, t1]
                                for (u_, n, c_, d_, t1) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
                                    if is_reserve_node(node=n) == :is_reserve_node_false
                    )
                    - sum(
                        flow[u_, n, c_, d_, t1]
                                for (u_, n, c_, d_, t1) in flow_indices(unit=u, commodity=c, direction = d, t=t_after)
                                    if is_reserve_node(node=n) == :is_reserve_node_false ##TODO: not to if reampdown reserveres are considered
                    )
                    <=
                    + (units_on[u, t_after] - units_started_up[u,t_after])
                         * ramp_down_limit(unit=u, commodity=c, direction=d) * unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                    + units_shut_down[u,t_after]
                        * max_shutdown_ramp(unit=u, commodity=c, direction=d) * unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                    - units_started_up[u,t_after]
                        * minimum_operating_point(unit=u, commodity=c) * unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                )
            end
        end
    end
end
