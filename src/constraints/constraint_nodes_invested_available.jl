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
    add_constraint_nodes_invested_available!(m::Model)

Limit the nodes_invested by the number of investment candidate nodes.
"""
function add_constraint_nodes_invested_available!(m::Model)
    @fetch nodes_invested = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:nodes_invested_available] = Dict(
        (node=n, stochastic_scenario=s, t=t) => @constraint(
            m,
            sum(
            + nodes_invested[n, s, t]
            for (n,s,t) in nodes_invested_available_indices(m)
                )
            <=
            + candidate_nodes[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
        ) for (n, s, t) in nodes_invested_available_indices(m)
    )
end
