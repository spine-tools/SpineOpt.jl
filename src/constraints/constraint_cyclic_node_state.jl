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
    add_constraint_nodal_balance!(m::Model)

Enforces cyclic constraint on node state over a temporal block.
"""
function add_constraint_cyclic_node_state!(m::Model)
    @fetch node_state = m.ext[:variables]
    cons = m.ext[:constraints][:cyclic_node_state] = Dict()
    for (n, blk) in indices(cyclic_condition)
        if has_state(node=n) == :value_true && cyclic_condition(node=n, temporal_block=blk)
            (n,t_start) = first(
                node_state_indices(
                    node=n,
                    t=first(t_before_t(t_after=first(time_slice(temporal_block=blk))))
                )
            )
            (n,t_end) = first(
                node_state_indices(
                    node=n,
                    t=last(time_slice(temporal_block=blk))
                )
            )
            cons[n, blk] = @constraint(
                m,
                node_state[n,t_end] >= node_state[n,t_start]
            )
        end
    end
end
