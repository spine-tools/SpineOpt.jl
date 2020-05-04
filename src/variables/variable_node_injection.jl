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
    node_injection_indices(filtering_options...)

A set of tuples for indexing the `node_injection` variable. Any filtering options can be specified
for `node`, and `t`.
"""
function node_injection_indices(;node=anything, t=anything)
    unique(
        (node=n, t=t_)
        for (n, tb) in node__temporal_block(node=node, _compact=false)
        for t_ in time_slice(temporal_block=tb, t=t)
    )
end

add_variable_node_injection!(m::Model) = add_variable!(m, :node_injection, node_injection_indices)