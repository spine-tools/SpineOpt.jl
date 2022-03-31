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
    add_constraint_units_invested_available!(m::Model)

Link units_invested_state to the sum of all units_invested_state_vintage, i.e. all investments differentiated by their investment year that are not decomissioned.
"""
function add_constraint_units_invested_available!(m::Model)
    @fetch units_invested_available, units_invested_available_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_invested_available] = Dict(
        (unit=u, stochastic_path=s, t=t) => @constraint(
            m,
            + units_invested_available[u, s, t]
            ==
            + expr_sum(
                units_invested_available_vintage[u, s, t_v, t]
                for (u, s, t_v, t) in units_invested_available_vintage_indices(
                            m;
                            unit=u,
                            stochastic_scenario=s,
                            t=t,
                            t_vintage = to_time_slice(
                                m;
                                t=TimeSlice(
                                    (isnothing(unit_investment_tech_lifetime(unit=u)) ?
                                    #FIXME: needs to look back in time
                                    t0.ref.x
                                    : start(t - unit_investment_tech_lifetime(unit=u))),
                                            end_(t))
                                )
                                #TODO: check that this is sufficient look back time
                            )
                ; init=0
                )
        ) for (u, s, t) in units_invested_available_indices(m;t=[t_before_t(m,t_after=time_slice(m)[1])...,time_slice(m)...])
    )
end
