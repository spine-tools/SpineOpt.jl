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
    constraint_max_ratio_out_in_trans(m::Model, trans)

Fix ratio between the output `trans` of a `node_group` to an input `trans` of a
`node_group` for each `connection` for which the parameter `max_ratio_out_in_trans`
is specified.
"""
function constraint_max_ratio_out_in_trans(m::Model, trans)
    for inds in indices(max_ratio_out_in_trans)
        time_slices_out = unique(
            x.t
            for x in trans_indices(;
                inds...,
                node=node_group__node(node_group=inds.node_group1)
            )
        )
        time_slices_in = unique(
            x.t
            for x in trans_indices(;
                inds...,
                node=node_group__node(node_group=inds.node_group2)
            )
        )
        # NOTE: `unique` is not really necessary but reduces the timeslices for the next steps
        involved_timeslices = sort!([time_slices_out; time_slices_in])
        overlaps = sort!(t_overlaps_t(time_slices_in, time_slices_out))
        if involved_timeslices != overlaps
            @warn "not all involved timeslices are overlapping, please check your temporal_blocks"
            # NOTE: this is a check for plausibility.
            # If the user e.g. wants to oconstrain one node of a connection for a certain amount of time,
            # while the other node is constraint for a longer period, "overlaps" becomes active
            involved_timeslices = overlaps
        end
        for t in t_lowest_resolution(involved_timeslices)
            @constraint(
                m,
                + sum(
                    trans[x] * duration(x.t)
                    for x in trans_indices(;
                        inds...,
                        node=node_group__node(node_group=inds.node_group1),
                        t=t_in_t(t_long=t)
                    )
                )
                <=
                + max_ratio_out_in_trans(;inds..., t=t)
                * sum(
                    trans[x] * duration(x.t)
                    for x in trans_indices(;
                        inds...,
                        node=node_group__node(node_group=inds.node_group2),
                        t=t_in_t(t_long=t)
                    )
                )
            )
        end
    end
end
