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
    node_pressure_indices(
        node=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `node_pressure` variable.
The keyword arguments act as filters for each dimension.
"""
function node_pressure_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything)
    inds = NamedTuple{(:node, :stochastic_scenario, :t),Tuple{Object,Object,TimeSlice}}[
        (node=n, stochastic_scenario=s, t=t)
        for (n, s, t) in node_stochastic_time_indices(m; node=node, stochastic_scenario=stochastic_scenario, t=t)
            if n in intersect(indices(max_node_pressure), indices(min_node_pressure))
    ]
    unique!(inds)
end

"""
    add_variable_node_pressure!(m::Model)

Add `node_pressure` variables to model `m`.
"""
function add_variable_node_pressure!(m::Model)
    t0 = start(current_window(m))
    add_variable!(
        m,
        :node_pressure,
        node_pressure_indices;
        lb=x -> min_node_pressure(node=x.node),
        ub=x -> max_node_pressure(node=x.node),
        fix_value=x -> fix_node_pressure(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
