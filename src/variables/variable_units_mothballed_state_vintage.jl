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
    units_invested_available_vintage_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function units_mothballed_state_vintage_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    t_vintage=anything,
    t=anything,
    temporal_block=anything,
)
    unit = members(unit)
    unique([
        (unit=u, stochastic_scenario=s, t_vintage=t_v, t=t)
        for (u, tb) in unit__investment_temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
        for (u, s, t_v) in unit_investment_stochastic_time_indices(
            m;
            unit=u,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t_vintage,
        )
        for (u, s, t) in unit_investment_stochastic_time_indices(
            m;
            unit=u,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
        if units_mothballing(unit=u) && t >= t_v #FIXME
    ])
end

"""
    add_variable_units_mothballed_state_vintage!(m::Model)

Add `units_mothballed_state_vintage` variables to model `m`.
"""
function add_variable_units_mothballed_state_vintage!(m::Model)
    add_variable!(m, :units_mothballed_state_vintage, units_mothballed_state_vintage_indices; lb=x -> 0,vintage=true)
end
