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
    constraint_fix_ratio_out_in_trans(m::Model, trans, time_slice, t_in_t)

Fix ratio between the output `trans` of a `commodity_group` to an input `trans` of a
`commodity_group` for each `connection` for which the parameter `fix_ratio_out_in_trans`
is specified.
"""
function constraint_fix_ratio_out_in_trans(m::Model, trans)
    @butcher @constraint(
        m,
        [
            (conn, node_in, node_out, tblock) in connection__node__node__temporal_block(),
            t in time_slice(temporal_block=tblock);
            fix_ratio_out_in_trans_t(connection=conn, node1=node_in, node2=node_out, temporal_block=tblock) != nothing
        ],
        + reduce(
            +,
            trans[c_out, node_out, conn, :out, t2]
            for (c_out) in commodity__node__connection__direction(node=node_out, connection=conn, direction=:out)
                for t2 in t_in_t(t_long=t)
                    if haskey(trans, (c_out, node_out, conn, :out, t2));
            init=0
        )
        ==
        + fix_ratio_out_in_trans_t(connection=conn, node1=node_in, node2=node_out, temporal_block=tblock)
            * reduce(
                +,
                trans[c_in, node_in, conn, :in, t2]
                for (c_in) in commodity__node__connection__direction(node=node_in, connection=conn, direction=:in)
                    for t2 in t_in_t(t_long=t)
                        if haskey(trans, (c_in, node_in, conn, :in, t2));
                init=0
            )
    )
end
