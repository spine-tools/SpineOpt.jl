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
    shut_down_unit_flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `shut_down_unit_flow` variable
where the keyword arguments act as filters for each dimension.
"""
function shut_down_unit_flow_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = members(unit)
    node = members(node)
    unique(
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u, n, d, tb) in shut_down_unit__node__direction__temporal_block(
            unit=unit,
            node=node,
            direction=direction,
            temporal_block=temporal_block,
            _compact=false,
        ) for (n, s, t) in node_stochastic_time_indices(
            m;
            node=n,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
    )
end

"""
    add_variable_shut_down_unit_flow!(m::Model)

Add `shut_down_unit_flow` variables to model `m`.
"""
function add_variable_shut_down_unit_flow!(m::Model)
    t0 = start(current_window(m))
    add_variable!(
        m,
        :shut_down_unit_flow,
        shut_down_unit_flow_indices;
        lb=x -> 0,
        fix_value=x -> fix_shut_down_unit_flow(
            unit=x.unit,
            node=x.node,
            direction=x.direction,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
