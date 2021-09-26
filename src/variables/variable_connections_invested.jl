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
    add_variable_connections_invested!(m::Model)

Add `connections_invested` variables to model `m`.
"""
function add_variable_connections_invested!(m::Model)
    t0 = _analysis_time(m)
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
        int=connections_invested_available_int,
    )
end
