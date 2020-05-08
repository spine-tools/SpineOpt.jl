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
    node_state_indices(filtering_options...)

A set of tuples for indexing the `node_state` variable. Any filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_state_indices(;node=anything, stochastic_scenario=anything, t=anything)
    inds = NamedTuple{(:node, :stochastic_scenario, :t),Tuple{Object,Object,TimeSlice}}[
        (node=n, stochastic_scenario=s, t=t)
        for n in node(node=node; has_state=:value_true)
        for (n, s, t) in node_stochastic_time_indices(node=n, stochastic_scenario=stochastic_scenario, t=t)
    ]
    unique!(inds)
end

function add_variable_node_state!(m::Model)
    add_variable!(
        m, 
        :node_state, 
        node_state_indices; 
        lb=x -> node_state_min(node=x.node),
        fix_value=x -> fix_node_state(node=x.node, t=x.t, _strict=false)
    )
end
