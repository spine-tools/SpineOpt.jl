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
    nonspin_starting_up_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function nonspin_starting_up_indices(;unit=anything, node=anything, stochastic_scenario=anything, t=anything)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    unique!([
        (unit=u, node=n, stochastic_scenario=s, t=t)
        for (u, n, d, tb) in nonspin_ramp_up_unit_flow_indices_rc(unit=unit, node=node, _compact=false)
        for (u, s, t) in unit_stochastic_time_indices(
            unit=u, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        ) #TODO: maybe retrieve s information from node to be more robust
    ])
end

function add_variable_nonspin_starting_up!(m::Model)
    add_variable!(
    	m,
    	:nonspin_starting_up, nonspin_starting_up_indices;
    	lb=x -> 0,
    	bin=units_on_bin,
    	int=units_on_int,
    	fix_value=x -> fix_nonspin_starting_up(unit=x.unit, node=x.node, t=x.t, _strict=false)
    )
end
