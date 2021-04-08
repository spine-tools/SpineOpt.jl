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
    node_voltage_angle_indices(filtering_options...)

A set of tuples for indexing the `node_voltage_angle` variable. Any filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_voltage_angle_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything)
    inds = NamedTuple{(:node, :stochastic_scenario, :t),Tuple{Object,Object,TimeSlice}}[
        (node=n, stochastic_scenario=s, t=t)
        for (n, s, t) in node_stochastic_time_indices(m; node=node, stochastic_scenario=stochastic_scenario, t=t)
            if has_voltage_angle(node=n)
    ]
    unique!(inds)
end

"""
    add_variable_node_voltage_angle!(m::Model)

Add `node_voltage_angle` variables to model `m`.
"""
function add_variable_node_voltage_angle!(m::Model)
    t0 = start(current_window(m))
    add_variable!(
        m,
        :node_voltage_angle,
        node_voltage_angle_indices;
        fix_value=x -> fix_node_voltage_angle(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
