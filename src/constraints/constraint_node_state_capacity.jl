#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    add_constraint_node_state_capacity!(m::Model)

Limit the maximum value of a `node_state` variable under `node_state_cap`, if it exists.
"""
function add_constraint_node_state_capacity!(m::Model)
    @fetch node_state = m.ext[:variables]
    m.ext[:constraints][:node_state_capacity] = Dict(
        (ng, s, t) => @constraint(
            m,
            + node_state[ng, s, t]
            <=
            + node_state_cap[(node=ng, stochastic_scenario=s, t=t)]
            # TODO: add investment decisions for storages
        )
        for ng in indices(node_state_cap)
        for (ng, s, t) in node_state_indices(node=ng)
    )
end
