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
    constraint_ramp_up(m::Model)

Limit the maximum ramp of `flow` of a `unit` if the parameters
`ramp_up_limit,unit_capacity,unit_conv_cap_to_flow, minimum_operating_point` exist.
"""

function add_constraint_ramp_up!(m::Model)
    @fetch flow, units_on,  units_started_up, ramp_up_flow, start_up_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:split_ramp_up] = Dict()
    for (u, n, c, d, t_before) in ramp_up_flow_indices()
        for (u, n, c, d, t_after) in flow_indices(unit=u,node=n,commodity=c,direction=d,t=t_before_t(t_before=t_before))
            constr_dict[u, n, c, d, t_before] = @constraint(
                m,
                flow[u, n, c, d, t_after]
                - flow[u, n, c, d, t_before]
                <=
                ramp_up_flow[u, n, c, d, t_before]
                +
                start_up_flow[u, n, c, d, t_after]
            )
        end
    end

    constr_dict1 = m.ext[:constraints][:start_up_ramp] = Dict()
    for (u, c, d) in intersect(indices(max_startup_ramp),indices(unit_capacity))
            for (u, t_after) in units_on_indices(unit=u)
                    constr_dict1[u, c, d, t_after] = @constraint(
                        m,
                        + sum(
                            start_up_flow[u, n, c, d, t1]
                                    for (u_, n, c_, d_, t1) in start_up_flow_indices(unit=u, commodity=c, direction = d, t=t_after)
                        )
                        <=
                        + units_started_up[u,t_after]
                            * max_startup_ramp(unit=u, commodity=c, direction=d)  *unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                    )
                    constr_dict2 = m.ext[:constraints][:min_start_up_ramp] = Dict()
                    constr_dict2[u, c, d, t_after] = @constraint(
                    m,
                    + sum(
                        start_up_flow[u, n, c, d, t1]
                                for (u_, n, c_, d_, t1) in start_up_flow_indices(unit=u, commodity=c, direction = d, t=t_after)
                    )
                    >=
                    + units_started_up[u,t_after]
                        * minimum_operating_point(unit=u, commodity=c)  *unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                )
        end
    end

    constr_dict = m.ext[:constraints][:ramp_up] = Dict()
    for (u, c, d) in intersect(indices(ramp_up_limit),indices(unit_capacity))
            for (u, t_after) in units_on_indices(unit=u)
                    for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
                    constr_dict[u, c, d, t_after] = @constraint(
                        m,
                        + sum(
                            ramp_up_flow[u_, n, c_, d_, t1]
                                    for (u_, n, c_, d_, t1) in ramp_up_flow_indices(unit=u, commodity=c, direction = d, t=t_before)
                        )
                        + sum(
                            flow[u_, n, c_, d_, t1]
                                    for (u_, n, c_, d_, t1) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
                                        if reserve_node_type(node=n) == :upward_spinning)
                        <=
                        + (units_on[u, t_after] - units_started_up[u,t_after])
                             * ramp_up_limit(unit=u, commodity=c, direction=d) *unit_conv_cap_to_flow(unit=u, commodity=c) *unit_capacity(unit=u, commodity=c, direction=d)
                    )
            end
        end
    end
end

update_constraint_ramp_up!(m::Model) = nothing
