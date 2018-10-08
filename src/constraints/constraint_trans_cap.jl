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
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


"""
    constraint_trans_cap(m::Model, trans)

Limit flow capacity of a commodity transfered between to nodes in a
specific direction `node1 -> node2`.
"""
function constraint_trans_cap(m::Model, trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            all([
            [i,j] in connection__node__node(connection=con),
            trans_cap_av_frac(connection=con, node1=i, node2=j, t=t) != nothing,
            trans_cap(connection=con) != nothing
            ])
        ],
        + (trans[con, i, j, t])
        <=
        + trans_cap_av_frac(connection=con, node1=i, node2=j, t=t)
            * trans_cap(connection=con)
    )
end
