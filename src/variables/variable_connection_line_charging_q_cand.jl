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
    connection_line_charging_q_cand_indices(
        connection=anything,
        node=anything,
        direction=anything,
        stochastic_scenario=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `xxx` variable.
The keyword arguments act as filters for each dimension.
"""
function connection_line_charging_q_cand_indices(
    m::Model;
    connection=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_blocks_by_period=nothing))

    connection_reactive_flow_indices(m;
        connection=intersect(SpineOpt.connection(is_candidate=true), connection),
        node=node,
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t,
        temporal_block=temporal_block
    )
end

"""
    add_variable_line_charging_q_cand!(m::Model)

Add `line_charging_q_cand` variables to model `m`, which represent capacitive line
charing of invested connections.
"""
function add_variable_line_charging_q_cand!(m::Model)
    add_variable!(
        m,
        :line_charging_q_cand,
        connection_line_charging_q_cand_indices
    )
end
