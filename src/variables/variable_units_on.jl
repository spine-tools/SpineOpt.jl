#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    units_on_indices(unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable where the keyword arguments act as filters
for each dimension.
"""
function units_on_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unique([
        (unit=u, stochastic_scenario=s, t=t)
        for (u, tb) in units_on__temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
        for (u, s, t) in unit_stochastic_time_indices(
            m;
            unit=u,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
    ])
end

"""
    units_on_bin(x)

Check if unit online variable type is defined as a binary.
"""
units_on_bin(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_binary

"""
    units_on_int(x)

Check if unit online variable type is defined as an integer.
"""
units_on_int(x) = online_variable_type(unit=x.unit) == :unit_online_variable_type_integer

"""
    add_variable_units_on!(m::Model)

Add `units_on` variables to model `m`.
"""
function add_variable_units_on!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :units_on,
        units_on_indices;
        lb=x -> 0,
        bin=units_on_bin,
        int=units_on_int,
        fix_value=x -> fix_units_on(
            unit=x.unit,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
