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
    units_invested_int(x)

Check if unit investment variable type is defined to be an integer.
"""

units_invested_int(x) = unit_investment_variable_type(unit=x.unit) == :unit_investment_variable_type_integer

"""
    fix_initial_units_invested()

If fix_units_invested_available is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_units_invested(m)
    for u in indices(candidate_units)
        t = last(history_time_slice(m))
        if fix_units_invested(unit=u, t=t, _strict=false) === nothing
            unit.parameter_values[u][:fix_units_invested] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
            unit.parameter_values[u][:starting_fix_units_invested] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
        end
    end
end

"""
    add_variable_units_invested!(m::Model)

Add `units_invested` variables to model `m`.
"""
function add_variable_units_invested!(m::Model)
    t0 = _analysis_time(m)
    fix_initial_units_invested(m)
    add_variable!(
        m,
        :units_invested,
        units_invested_available_indices;
        lb=x -> 0,
        fix_value=x -> fix_units_invested(
            unit=x.unit,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
        int=units_invested_int,
    )
end