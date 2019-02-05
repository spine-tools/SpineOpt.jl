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
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
TODO: for electrical lines this constraint is obsolete unless
a trade based representation is used.
"""
function constraint_nodal_balance(m::Model, flow, trans)
    @butcher for n in node(), t=1:number_of_timesteps(time=:timer)
        @constraint(
            m,
            + sum(flow[c, n, u, :out, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:out))
            ==
            + (demand(node=n, t=t) != nothing && demand(node=n, t=t))
            + sum(flow[c, n, u, :in, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:in))
            + sum(trans[conn, n, t] for conn in connection__node(node=n))
        )
    end
end
