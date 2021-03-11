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
    node_injection_indices(filtering_options...)

A set of tuples for indexing the `node_injection` variable where filtering options can be specified for `node`, and `t`.
"""
function node_injection_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything, temporal_block=temporal_block(representative_periods_mapping=nothing) )
    node_stochastic_time_indices(m; node=node, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block)
end

"""
    add_variable_node_injection!(m::Model)

Add `node_injection` variables to model `m`.
"""
add_variable_node_injection!(m::Model) = add_variable!(m, :node_injection, node_injection_indices)
