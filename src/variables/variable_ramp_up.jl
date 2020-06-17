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
    ramp_up_unit_flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `flow` variable.
The keyword arguments act as filters for each dimension.
"""
### ramp_up_unit_flow
#TODO: only generate if ramp_limit is defined
#TODO: better improve to unit_parameter: use_ramps_true
function ramp_up_unit_flow_indices(;unit=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything
)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    ind = [
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u,n,d) in indices(ramp_up_limit)
        for (u, n, d, tb) in unit_flow_indices_rc(
            unit=intersect(unit,u), node=intersect(node,expand_node_group(n)), direction=intersect(direction,d), _compact=false
        )
        for (n, s, t) in node_stochastic_time_indices(
            node=n, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
        if reserve_node_type(node=n) != :upward_nonspinning
    ]
    unique!(ind)
end

function add_variable_ramp_up_unit_flow!(m::Model)
    @warn "unique for indices is probably not the most performant, try to reformulate"
    add_variable!(
        m,
        :ramp_up_unit_flow,
        ramp_up_unit_flow_indices;
        lb=x -> 0,
        fix_value=x -> fix_ramp_up_unit_flow(unit=x.unit, node=x.node, direction=x.direction, t=x.t, _strict=false)
    )
end
