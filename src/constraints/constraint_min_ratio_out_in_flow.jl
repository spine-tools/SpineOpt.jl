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
    constraint_min_ratio_out_in_flow(m::Model)

Fix ratio between the output `flow` of a `commodity_group` to an input `flow` of a
`commodity_group` for each `unit` for which the parameter `min_ratio_out_in_flow`
is specified.
"""
@catch_undef function constraint_min_ratio_out_in_flow(m::Model)
    @fetch flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:min_ratio_out_in_flow] = Dict()
    for (u, c_out, c_in) in indices(min_ratio_out_in_flow)
        involved_timeslices = [t for (u, n, c, d, t) in var_flow_indices(unit=u, commodity=[c_out, c_in])]
        for t in t_lowest_resolution(involved_timeslices)
            constr_dict[u, c_out, c_in, t] = @constraint(
                m,
                + sum(
                    flow[u_, n, c_out_, d, t1] * duration(t1)
                    for (u_, n, c_out_, d, t1) in flow_indices(
                        unit=u, commodity=c_out, direction=:to_node, t=t_in_t(t_long=t)
                    )
                )
                >=
                + min_ratio_out_in_flow(unit=u, commodity1=c_out, commodity2=c_in, t=t)
                * sum(
                    flow[u_, n, c_in_, d, t1] * duration(t1)
                    for (u_, n, c_in_, d, t1) in flow_indices(
                        unit=u, commodity=c_in, direction=:from_node, t=t_in_t(t_long=t)
                    )
                )
            )
        end
    end
end
