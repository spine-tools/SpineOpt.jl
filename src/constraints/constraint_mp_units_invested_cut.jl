#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    add_constraint_min_up_time!(m::Model)

Constraint running by minimum up time.
"""

function add_constraint_mp_units_invested_cut!(m::Model)
    @fetch mp_objective_lowerbound, units_started_up = m.ext[:variables]
    cons = m.ext[:constraints][:mp_units_invested_cut] = Dict()
    for bi in benders_iteration()
        cons[bi] = @constraint(
            m,
            + mp_objective_lowerbound 
            >=
            + sp_objective(benders_iteration=bi)
            - sum(
                + ( - mp_units_invested_available[u, t] 
                    - units_invested_available_bi[bi, u, t]
                )
                * units_available_mv(benders_iteration=bi, unit=u, t=t)                
                for (u, s, t) in mp_units_invested_available_indices()
            )
        )
    end
end