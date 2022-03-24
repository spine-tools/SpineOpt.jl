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
    add_constraint_units_invested_state_vintage!(m::Model)

Constrain units_invested_state_vintage by the investment lifetime of a unit and early decomissioning.
"""
function add_constraint_units_invested_available_vintage!(m::Model)
    @fetch units_invested_available_vintage, units_invested_state_vintage, units_mothballed_state_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_invested_available_vintage] = Dict(
        (unit=u, stochastic_path=s, t_vintage=t_v, t=t) => @constraint(
            m,
            + units_invested_available_vintage[u, s, t_v, t]
            ==
            + units_invested_state_vintage[u, s, t_v, t]
            - (units_mothballing(unit=u) ? units_mothballed_state_vintage[u, s, t_v, t] : 0)
        ) for (u, s, t_v, t) in units_invested_available_vintage_indices(m)
    )
end
