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
    unit_flow_op_indices(
        unit=anything,
        node=anything,
        direction=anything,
        operating_point=anything,
        s=anything
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `unit_flow` variable.
The keyword arguments act as filters for each dimension.
"""
function unit_flow_op_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    i=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing) 
)
    unit = members(unit)
    node = members(node)
    [
        (unit=u, node=n, direction=d, i=i, stochastic_scenario=s, t=t)
        for (u, n) in indices(operating_points, unit=unit, node=node)
        for (u, n, d, tb) in unit__node__direction__temporal_block(
            unit=u, node=n, direction=direction, temporal_block=temporal_block,_compact=false
            )
        for i in intersect(i, 1:length(operating_points(unit=u, node=n, direction=d)))
        for
        (n, s, t) in
        node_stochastic_time_indices(m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t)
    ]
end

"""
    add_variable_unit_flow_op!(m::Model)

Add `unit_flow_op` variables to model `m`.
"""
function add_variable_unit_flow_op!(m::Model)
    t0 = startref(current_window(m))
    add_variable!(
        m,
        :unit_flow_op,
        unit_flow_op_indices;
        lb=x -> 0,
        fix_value=x -> fix_unit_flow_op(
            unit=x.unit,
            node=x.node,
            direction=x.direction,
            i=x.i,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
