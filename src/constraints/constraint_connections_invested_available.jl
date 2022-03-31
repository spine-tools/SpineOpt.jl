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
    add_constraint_connections_invested_available!(m::Model)

Link connections_invested_state to the sum of all connections_invested_available_vintage, i.e. all investments differentiated by their investment year that are not decomissioned.
"""
function add_constraint_connections_invested_available!(m::Model)
    @fetch connections_invested_available, connections_invested_available_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:connections_invested_available] = Dict(
        (connection=c, stochastic_path=s, t=t) => @constraint(
            m,
            + connections_invested_available[c, s, t]
            ==
            + expr_sum(
                connections_invested_available_vintage[c, s, t_v, t]
                for (c, s, t_v, t) in connections_invested_available_vintage_indices(
                            m;
                            connection=c,
                            stochastic_scenario=s,
                            t=t,
                            t_vintage = to_time_slice(
                                m;
                                t=TimeSlice(
                                    isnothing(connection_investment_tech_lifetime(connection=c)) ?
                                    t0.ref.x #FIXME: needs to look back in history
                                    : start(t - connection_investment_tech_lifetime(connection=c) -
                                        (iszero(connection_lead_time(connection=c).value) ? Year(0) : connection_lead_time(connection=c))),
                                            end_(t))
                                )
                                #TODO: check that this is sufficient look back time
                            )
                ; init=0
                )
        ) for (c, s, t) in connections_invested_available_indices(m;t=[t_before_t(m,t_after=time_slice(m)[1])...,time_slice(m)...])
    )
end
