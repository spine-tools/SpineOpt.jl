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
    units_invested_available_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_invested_available` variable.
The keyword arguments act as filters for each dimension.
"""

function units_invested_available_indices(;unit=anything, stochastic_scenario=anything, t=anything)
    [
        (unit=u, stochastic_scenario=s, t=t)
        for (u, tb) in unit__investment_temporal_block(unit=unit, _compact=false)
        for (u, s, t) in unit_investment_stochastic_time_indices(
            unit=u, stochastic_scenario=stochastic_scenario, temporal_block=tb, t=t
        )
    ]
end

units_invested_available_int(x) = unit_investment_variable_type(unit=x.unit) == :unit_investment_variable_type_integer

"""
    fix_initial_units_invested_available()

If fix_units_invested_available is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_units_invested_available()
    for u in indices(candidate_units)        
        for tb in unit__investment_temporal_block(unit=u)
            t_after = first(time_slice(temporal_block=tb))            
            for t_before in t_before_t(t_after=t_after)                               
                if fix_units_invested_available(unit=u, t=t_before, _strict=false) === nothing
                    unit.parameter_values[u][:fix_units_invested_available] = parameter_value(TimeSeries([start(t_before)], [0], false, false))
                end
            end
        end
    end
end


function add_variable_units_invested_available!(m::Model)
    fix_initial_units_invested_available()
    add_variable!(
    	m,
    	:units_invested_available, units_invested_available_indices;
    	lb=x -> 0,
    	int=units_invested_available_int,
    	fix_value=x -> fix_units_invested_available(unit=x.unit, t=x.t, _strict=false)
    )
end

