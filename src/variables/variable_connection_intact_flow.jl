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
    connection_intact_flow_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `connection_intact_flow` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_intact_flow_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    use_connection_intact_flow(model=m.ext[:spineopt].instance) || return ()
    connection_flow_indices(
        m;
        connection=connection,
        node=node,
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t,
        temporal_block=temporal_block,
    )
end

"""
    add_variable_connection_intact_flow!(m::Model)

Add `connection_intact_flow` variables to model `m`.
"""
function add_variable_connection_intact_flow!(m::Model)
    add_variable!(
        m,
        :connection_intact_flow,
        connection_intact_flow_indices;
        lb=constant(0),
        fix_value=fix_connection_intact_flow,
        initial_value=initial_connection_intact_flow,
        non_anticipativity_time=connection_intact_flow_non_anticipativity_time,
        non_anticipativity_margin=connection_intact_flow_non_anticipativity_margin,
    )
end
