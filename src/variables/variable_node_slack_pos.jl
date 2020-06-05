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
    node_state_indices(filtering_options...)

A set of tuples for indexing the `node_state` variable. Any filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_slack_indices(;node=anything, stochastic_scenario=anything, t=anything)
    inds = NamedTuple{(:node, :stochastic_scenario, :t),Tuple{Object,Object,TimeSlice}}[
        (node=n, stochastic_scenario=s, t=t)
        for n in filter(n -> n in node, collect(indices(node_slack_penalty)))
        for (n, s, t) in node_stochastic_time_indices(node=n, stochastic_scenario=stochastic_scenario, t=t)
    ]
    unique!(inds)
end

add_variable_node_slack_pos!(m::Model) = add_variable!(m, :node_slack_pos, node_slack_indices; lb=x -> 0)
