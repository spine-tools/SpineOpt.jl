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
    nonspin_units_started_up_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `nonspin_units_started_up` variable
where the keyword arguments act as filters for each dimension.
"""
function nonspin_units_started_up_indices(
    m::Model;
    unit=anything,
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node = intersect(SpineOpt.node(is_reserve_node=true, is_non_spinning=true), members(node))
    (
        (unit=u, node=n, stochastic_scenario=s, t=t)
        for (u, n, d, s, t) in unit_flow_indices(
            m; unit=unit, node=node, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block
        )
    )
end

"""
    add_variable_nonspin_units_started_up!(m::Model)

Add `nonspin_units_started_up` variables to model `m`.
"""
function add_variable_nonspin_units_started_up!(m::Model)
    add_variable!(
        m,
        :nonspin_units_started_up,
        nonspin_units_started_up_indices;
        lb=constant(0),
        bin=units_on_bin,
        int=units_on_int,
        fix_value=fix_nonspin_units_started_up,
        initial_value=initial_nonspin_units_started_up,
        required_history_period=maximum_parameter_value(min_up_time),
    )
end
