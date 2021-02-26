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

A set of tuples for indexing the `node_state` variable where filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_state_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything, temporal_block=anything)
    unique(
        (node=n, stochastic_scenario=s, t=t) for (n, tb) in node_with_state__temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for
        (n, s, t) in
        node_stochastic_time_indices(m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t)
    )
end

"""
    add_variable_node_state!(m::Model)

Add `node_state` variables to model `m`.
"""
function add_variable_node_state!(m::Model)
    t0 = startref(current_window(m))
    add_variable!(
        m,
        :node_state,
        node_state_indices;
        lb=x -> node_state_min(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
        fix_value=x -> fix_node_state(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
