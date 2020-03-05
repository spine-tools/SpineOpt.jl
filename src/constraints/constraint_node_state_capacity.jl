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
    add_constraint_node_state_capacity!(m::Model)

Limit the maximum value of a `node_state` variable under `node_state_cap`,
if it exists.
"""
function add_constraint_node_state_capacity!(m::Model)
    @fetch node_state = m.ext[:variables]
    cons = m.ext[:constraints][:node_state_capacity] = Dict()
    for (n,) in indices(node_state_cap)
        for (n, t) in node_state_indices(node=n)
            cons[n, t] = @constraint(
                m,
                node_state[n, t]
                <=
                node_state_cap(node=n, t=t)
            )
        end
    end
end

function update_constraint_node_state_capacity!(m::Model)
    cons = m.ext[:constraints][:node_state_capacity]
    for (n,) in indices(node_state_cap)
        for (n, t) in node_state_indices(node=n)
            set_normalized_rhs(
                cons[n, t],
                node_state_cap(node=n, t=t)
            )
        end
    end
end