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
    add_constraint_mp_units_invested_cut!(m::Model)

Adds Benders optimality cuts for the units_available constraint. This tells the master problem the mp_objective
    cost improvement that is possible for an increase in the number of units available for a unit.
"""

function add_constraint_mp_units_invested_cuts!(m::Model)
    @fetch mp_objective_lowerbound, units_invested_available, connections_invested_available, storages_invested_available = m.ext[:variables]
    m.ext[:constraints][:mp_units_invested_cut] = Dict(
        (benders_iteration=bi, t=t1) => @constraint(
            m,
            +mp_objective_lowerbound[m1, t1] >=
            + sp_objective_value_bi(benders_iteration=bi) 
            # operating cost benefit from investments in units
            + expr_sum(
                ( + units_invested_available[u, s, t]  
                  - units_invested_available_bi(benders_iteration=bi, unit=u, t=t)
                ) * units_available_mv(benders_iteration=bi, unit=u, t=t)
                for (u, s, t) in units_invested_available_indices(m);
                init=0,
            )
            # operating cost benefit from investments in connections
            + expr_sum(
                ( + connections_invested_available[c, s, t]
                  - connections_invested_available_bi(benders_iteration=bi, connection=c, t=t)
                ) * connections_invested_available_mv(benders_iteration=bi, connection=c, t=t)
                for (c, s, t) in connections_invested_available_indices(m);
                init=0,
            )
            # operating cost benefit from investments in storages
            + expr_sum(
                ( + storages_invested_available[n, s, t]
                  - storages_invested_available_bi(benders_iteration=bi, node=n, t=t)
                ) * storages_invested_available_mv(benders_iteration=bi, node=n, t=t)
                for (n, s, t) in storages_invested_available_indices(m);
                init=0,
            )
        ) for bi in last(benders_iteration()) for (m1, t1) in mp_objective_lowerbound_indices(m)
    )
end
