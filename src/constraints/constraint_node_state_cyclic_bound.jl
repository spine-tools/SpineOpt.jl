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
    constraint_node_state_cyclic_bound(m::Model, state)

Fix the first and last modelled values of node state variables as equal.
"""
function constraint_node_state_cyclic_bound(m::Model, state)
    @butcher for (c,n) in commodity__node()
        state_cyclic_bound(commodity=c, node=n) != nothing || continue
        @constraint(
            m,
            # Node commodity state on the first time step
            state[c, n, 0]
            ==
            # Node commodity state on the last time step
            state[c, n, number_of_timesteps(time=:timer)]
        )
    end
end
