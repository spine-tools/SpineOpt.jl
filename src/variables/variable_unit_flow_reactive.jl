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
    add_variable_unit_flow_reactive!(m::Model)

Add `unit_flow_reactive` variables to model `m`. The reactive power flow from unit to node
(injection of reactive power) or from node to unit (absorption of reactive power).
"""
function add_variable_unit_flow_reactive!(m::Model)

    add_variable!(
        m,
        :unit_flow_reactive,
        unit_flow_reactive_indices;
        lb=constant(0),
        ub=unit_flow_reactive_ub
    )
end

function unit_flow_reactive_ub(m; unit, node, direction, kwargs...)
    (
        realize(unit_capacity_reactive(m; unit=unit, node=node, direction=direction, kwargs..., _strict=false)) === nothing
        || has_online_variable(unit=unit)
        || members(node) != [node]
    ) && return NaN
    unit_capacity_reactive(m; unit=unit, node=node, direction=direction, kwargs..., _default=NaN) * (
        + existing_units(m; unit=unit, kwargs..., _default=_default_nb_of_units(unit))
        + something(investment_count_max_cumulative(m; unit=unit, kwargs...), 0)
    )
end

"""
    unit_flow_reactive_indices(
        m,
        unit=anything,
        node=anything,
        direction=anything,
        s=anything
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `unit_flow_reactive` variable 
where the keyword arguments act as filters for each dimension.
"""
function unit_flow_reactive_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_blocks_by_period=nothing),
)
    ((unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u, n, d, s, t) in unit_flow_indices(m; unit = unit, 
                                    node = intersect(members(node), SpineOpt.node(has_acflow=true)), 
                                    direction=direction, 
                                    stochastic_scenario = stochastic_scenario, 
                                    t=t, temporal_block = temporal_block)
        
    
    )
end
