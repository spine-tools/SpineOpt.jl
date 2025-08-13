#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    node_slack_indices(filtering_options...)
"""
function node_slack_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node = intersect(node_with_slack_penalty(), node)
    node_stochastic_time_indices(
        m; node=node, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block
    )
end

"""
    add_variable_node_slack_pos!(m::Model)

Add `node_slack_pos` variables to model `m`.
"""
add_variable_node_slack_pos!(m::Model) = add_variable!(m, :node_slack_pos, node_slack_indices; lb=constant(0))
