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
    constraint_fix_ratio_out_in_trans(m::Model, trans)

Fix ratio between the output `trans` of a `commodity_group` to an input `trans` of a
`commodity_group` for each `connection` for which the parameter `fix_ratio_out_in_trans`
is specified.
"""
function constraint_fix_ratio_out_in_trans(m::Model, trans, timeslicemap)
    #if isdefined(:fix_ratio_out_in_trans)
    @butcher @constraint(
        m,
        [
            conn in connection(),
            cg_out in commodity_group(),
            cg_in in commodity_group(),
            node_in in node(),
            node_out in node(),
            t=1:number_of_timesteps(time_stage=:timer);
            fix_ratio_out_in_trans(connection=conn, node1=node_in, node2=node_out) != nothing
        ],
        + sum(trans[c_out, node_out, conn, :out, t]
            for (c_out) in commodity__node__connection__direction(node=node_out,connection=conn, direction=:out))    #    if c_out in commodity_group__commodity(commodity_group=cg_out))
        ==
        + fix_ratio_out_in_trans(connection=conn, node1=node_in, node2=node_out)
            * sum(trans[c_in, node_in, conn, :in, t]
                for (c_in) in commodity__node__connection__direction(node=node_in,connection=conn, direction=:in)) #    if c_in in commodity_group__commodity(commodity_group=cg_in))
    )
end
#end
