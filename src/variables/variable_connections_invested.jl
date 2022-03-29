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
    connections_invested_int(x)

Check if conneciton investment variable type is defined to be an integer.
"""

function connections_invested_int(x)
    connection_investment_variable_type(connection=x.connection) == :variable_type_integer
end

"""
    fix_initial_connections_invested()

If fix_connections_invested_available is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_connections_invested(m)
    for conn in indices(candidate_connections)
        t = last(history_time_slice(m; temporal_block=connection__investment_temporal_block(connection=conn)))
        if fix_connections_invested(connection=conn, t=t, _strict=false) === nothing
            connection.parameter_values[conn][:fix_connections_invested] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
            connection.parameter_values[conn][:starting_fix_connections_invested] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
        end
    end
end

"""
    add_variable_connections_invested!(m::Model)

Add `connections_invested` variables to model `m`.
"""
function add_variable_connections_invested!(m::Model)
    t0 = _analysis_time(m)
    fix_initial_connections_invested(m)
    add_variable!(
        m,
        :connections_invested,
        connections_invested_available_indices;
        lb=x -> 0,
        fix_value=x -> fix_connections_invested(
            connection=x.connection,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
        int=connections_invested_int,
    )
end
