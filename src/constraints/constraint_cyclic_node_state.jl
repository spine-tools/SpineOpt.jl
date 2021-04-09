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
    add_constraint_cyclic_node_state!(m::Model)

Enforces cyclic constraint on node state over a temporal block.
"""
function add_constraint_cyclic_node_state!(m::Model)
    @fetch node_state = m.ext[:variables]
    m.ext[:constraints][:cyclic_node_state] = Dict(
    (node=n, stochastic_scenario=s, t=t_end) => @constraint(
            m, node_state[n, s, t_end] >= node_state[n, s, t_start]
            ) for (n, blk) in indices(cyclic_condition) if cyclic_condition(node=n, temporal_block=blk)
                    for (n, s, t_start) in node_state_indices(m;node=n, t=first(t_before_t(m;t_after=first(time_slice(m;temporal_block=blk)))))
                        for (n, s, t_end) in node_state_indices(m;node=n, t=last(time_slice(m;temporal_block=blk)))
    )
end
