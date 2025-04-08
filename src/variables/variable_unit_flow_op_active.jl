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
    add_variable_unit_flow_op_active!(m::Model)

Add `unit_flow_op_active` variables to model `m`.
"""
function add_variable_unit_flow_op_active!(m::Model)
    add_variable!(
        m, :unit_flow_op_active, unit_flow_op_active_indices; lb=constant(0), bin=units_on_bin, int=units_on_int
    )
end

function unit_flow_op_active_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    i=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    (
        (unit=u, node=n, direction=d, i=i, stochastic_scenario=s, t=t)
        for (u, n, d, i, s, t) in unit_flow_op_indices(
            m; 
            unit=unit, 
            node=node, 
            direction=direction, 
            i=i, 
            stochastic_scenario=stochastic_scenario, 
            t=t, 
            temporal_block=temporal_block
        )
        if ordered_unit_flow_op(unit=u, node=n, direction=d, _default=false)
    )
end
