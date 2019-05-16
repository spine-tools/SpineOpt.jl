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
    constraint_max_ratio_out_in_trans(m::Model)

Fix ratio between the output `trans` of a `node_group` to an input `trans` of a
`node_group` for each `connection` for which the parameter `max_ratio_out_in_trans`
is specified.
"""
function constraint_max_ratio_out_in_trans(m::Model)
    @fetch trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:max_ratio_out_in_trans] = Dict()
    for (conn, ng_out, ng_in) in indices(max_ratio_out_in)
        involved_timeslices = [
            t for (conn, n, c, d, t) in trans_indices(
                connection=conn, node=node_group__node(node_group=[ng_in, ng_out])
            )
        ]
        for t in t_lowest_resolution(involved_timeslices)
            constr_dict[conn, ng_out, ng_in, t] = @constraint(
                m,
                + sum(
                    trans[conn, n_out, c, :to_node, t1] * duration(t1)
                    for (conn, n_out, c, d, t1) in trans_indices(
                        node=node_group__node(node_group=ng_out),
                        direction=:to_node,
                        t=t_in_t(t_long=t)
                    )
                )
                <=
                + max_ratio_out_in(connection=conn, node_group1=ng_out, node_group2=ng_in, t=t)
                * sum(
                    trans[conn, n_in, c, :from_node, t1] * duration(t1)
                    for (conn, n_in, c, d, t1) in trans_indices(
                        node=node_group__node(node_group=ng_in),
                        direction=:from_node,
                        t=t_in_t(t_long=t)
                    )
                )
            )
        end
    end
end
