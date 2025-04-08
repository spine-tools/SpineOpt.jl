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
    node_pressure_indices(
        node=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `node_pressure` variable.
The keyword arguments act as filters for each dimension.
"""
function node_pressure_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node_stochastic_time_indices(
        m;
        node=intersect(members(node), SpineOpt.node(has_pressure=true)),
        stochastic_scenario=stochastic_scenario,
        t=t,
        temporal_block=temporal_block,
    )
end

"""
    add_variable_node_pressure!(m::Model)

Add `node_pressure` variables to model `m`.
"""
function add_variable_node_pressure!(m::Model)
    add_variable!(
        m,
        :node_pressure,
        node_pressure_indices;
        lb=constant(0),
        fix_value=fix_node_pressure,
        initial_value=initial_node_pressure
    )
end
