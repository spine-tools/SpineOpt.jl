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
    add_constraint_units_decommissioned_vintage!(m::Model)

Link units_decommissioned to the sum of all units_decommissioned_vintage, i.e. all investments differentiated by their investment year that are not decomissioned.
"""
function add_constraint_units_decommissioned!(m::Model)
    @fetch units_decommissioned, units_decommissioned_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_decommissioned] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            + units_decommissioned[u, s, t]
            ==
            + expr_sum(
                units_decommissioned_vintage[u, s, t_v, t]
                for (u, s, t_v, t) in units_invested_available_vintage_indices(
                            m;
                            unit=u,
                            stochastic_scenario=s,
                            t=t,
                            t_vintage = to_time_slice(
                                m;
                                t=TimeSlice(start(t - unit_investment_tech_lifetime(unit=u)), end_(t))
                                )
                            )
                ; init=0
                )
        ) for (u, s, t) in units_invested_available_indices(m)
    )
end
