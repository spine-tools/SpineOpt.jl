#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    unit_flow_indices(
        unit=anything,
        node=anything,
        direction=anything,
        s=anything
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `unit_flow` variable where the keyword arguments act as filters
for each dimension.
"""
function unit_flow_indices(
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
    (
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u, n, d, tb) in unit__node__direction__temporal_block(
            unit=unit, node=node, direction=direction, temporal_block=temporal_block, _compact=false
        )
        for (n, s, t) in node_stochastic_time_indices(
            m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
    )
end

function unit_flow_ub_as_number(; unit, node, direction, kwargs...)
    unit_flow_capacity(; unit=unit, node=node, direction=direction, kwargs..., _default=NaN) * (
        + number_of_units(; unit=unit, kwargs..., _default=1)
        + candidate_units(; unit=unit, kwargs..., _default=0)
    )
end

function unit_flow_ub_as_call(; kwargs...)
    unit_flow_capacity[(; unit=unit, node=node, direction=direction, kwargs..., _default=NaN)] * (
        + number_of_units[(; unit=unit, kwargs..., _default=1)]
        + candidate_units[(; unit=unit, kwargs..., _default=0)]
    )
end

"""
    add_variable_unit_flow!(m::Model)

Add `unit_flow` variables to model `m`.
"""
function add_variable_unit_flow!(m::Model)
    add_variable!(
        m,
        :unit_flow,
        unit_flow_indices;
        lb=min_unit_flow,
        ub=FlexParameter(unit_flow_ub_as_number, unit_flow_ub_as_call),
        fix_value=fix_unit_flow,
        initial_value=initial_unit_flow,
        non_anticipativity_time=unit_flow_non_anticipativity_time,
        non_anticipativity_margin=unit_flow_non_anticipativity_margin,
    )
end
