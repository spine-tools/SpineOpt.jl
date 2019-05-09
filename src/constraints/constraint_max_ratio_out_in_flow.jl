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
    constraint_max_ratio_out_in_flow(m::Model)

Fix ratio between the output `flow` of a `commodity_group` to an input `flow` of a
`commodity_group` for each `unit` for which the parameter `max_ratio_out_in_flow`
is specified.
"""
function constraint_max_ratio_out_in_flow(m::Model)
    @fetch flow = m.ext[:variables]
    for (u, cg_out, cg_in) in indices(max_ratio_out_in)
        time_slices_out = unique(
            t for (u, n, c_out, d, t) in flow_indices(
                unit=u, commodity=commodity_group__commodity(commodity_group=cg_out), direction=:to_node
            )
        )
        time_slices_in = unique(
            t for (u, n, c_in, d, t) in flow_indices(
                unit=u, commodity=commodity_group__commodity(commodity_group=cg_in), direction=:from_node
            )
        )
        (!isempty(time_slices_out) && !isempty(time_slices_in)) || continue
        # NOTE: the unique is not really necessary but reduces the timeslices for the next steps
        involved_timeslices = sort!(unique!([time_slices_out; time_slices_in]))
        overlaps = sort!(t_overlaps_t(time_slices_in, time_slices_out))
        if involved_timeslices != overlaps
            @warn "not all involved timeslices are overlapping, check your temporal_blocks"
            # NOTE: this is a check for plausibility.
            # If the user e.g. wants to oconstrain one commodity of a unit for a certain amount of time,
            # while the other commodity is constraint for a longer period, "overlaps" becomes active
            involved_timeslices = overlaps
        end
        for t in t_lowest_resolution(involved_timeslices)
            @constraint(
                m,
                + sum(
                    flow[u, n, c_out, d, t1] * duration(t1)
                    for (u, n, c_out, d, t1) in flow_indices(
                        commodity=commodity_group__commodity(commodity_group=cg_out),
                        direction=:to_node,
                        t=t_in_t(t_long=t)
                    )
                )
                <=
                + max_ratio_out_in(unit=u, commodity_group1=cg_out, commodity_group2=cg_in, t=t)
                * sum(
                    flow[u, n, c_in, d, t1] * duration(t1)
                    for (u, n, c_in, d, t1) in flow_indices(
                        commodity=commodity_group__commodity(commodity_group=cg_in),
                        direction=:from_node,
                        t=t_in_t(t_long=t)
                    )
                )
            )
        end
    end
end
