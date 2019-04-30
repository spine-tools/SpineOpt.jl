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
    for (conn, ng_out, ng_in) in max_ratio_out_in_trans_indices()
        time_slices_out = unique(
            t for (conn, n_out, c, d, t) in trans_indices(
                connection=conn, node=node_group__node(node_group=ng_out), direction=:out
            )
        )
        time_slices_in = unique(
            t for (conn, n_in, c, d, t) in trans_indices(
                connection=conn, node=node_group__node(node_group=ng_in), direction=:in
            )
        )
        #NOTE: the unique is not really necessary but reduces the timeslices for the next steps
        involved_timeslices = sort!([time_slices_out;time_slices_in])
        overlaps = sort!(t_overlaps_t(time_slices_in, time_slices_out))
        if involved_timeslices != overlaps
            @warn "Not all involved timeslices are overlapping, check your temporal_blocks"
            # NOTE: this is a check for plausibility.
            # If the user e.g. wants to oconstrain one node of a connection for a certain amount of time,
            # while the other node is constraint for a longer period, "overlaps" becomes active
            involved_timeslices = overlaps
        end
        for t in t_lowest_resolution(involved_timeslices)
            @constraint(
                m,
                + sum(
                    trans[conn, n_out, c, :out, t1] * duration(t1)
                    for (conn, n_out, c, d, t1) in trans_indices(
                        node=node_group__node(node_group=ng_out),
                        direction=:out,
                        t=t_in_t(t_long=t)
                    )
                )
                <=
                + max_ratio_out_in_trans(connection=conn, node_group1=ng_out, node_group2=ng_in, t=t)
                * sum(
                    trans[conn, n_in, c, :in, t1] * duration(t1)
                    for (conn, n_in, c, d, t1) in trans_indices(
                        node=node_group__node(node_group=ng_in),
                        direction=:in,
                        t=t_in_t(t_long=t)
                    )
                )
            )
        end
    end
end
