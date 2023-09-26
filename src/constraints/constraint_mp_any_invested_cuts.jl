#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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

Adds Benders optimality cuts.
This tells the master problem the improvement of the subproblem objective value that is possible for an increase
in the number of investments.
"""
function add_constraint_mp_any_invested_cuts!(m::Model)
    @fetch (
        sp_objective_upperbound,
        units_invested_available,
        connections_invested_available,
        storages_invested_available
    ) = m.ext[:spineopt].variables
    merge!(
        get!(m.ext[:spineopt].constraints, :mp_any_invested_cut, Dict()),
            Dict(
            (benders_iteration=bi, model=i) => @constraint(
                m,
                + sp_objective_upperbound[i]
                >=
                + sp_objective_value_bi(benders_iteration=bi)
                # operating cost benefit from investments in units
                + expr_sum(
                    (
                        + units_invested_available[u, s, t]
                        - internal_fix_units_invested_available(unit=u, stochastic_scenario=s, t=t)
                    )
                    * window_sum(units_invested_available_mv(unit=u, stochastic_scenario=s), t)
                    for (u, s, t) in units_invested_available_indices(m)
                    init=0,
                )
                # operating cost benefit from investments in connections
                + expr_sum(
                    (
                        + connections_invested_available[c, s, t]
                        - internal_fix_connections_invested_available(connection=c, stochastic_scenario=s, t=t)
                    )
                    * window_sum(connections_invested_available_mv(connection=c, stochastic_scenario=s), t)
                    for (c, s, t) in connections_invested_available_indices(m)
                    init=0,
                )
                # operating cost benefit from investments in storages
                + expr_sum(
                    (
                        + storages_invested_available[n, s, t]
                        - internal_fix_storages_invested_available(node=n, stochastic_scenario=s, t=t)
                    )
                    * window_sum(storages_invested_available_mv(node=n, stochastic_scenario=s), t)
                    for (n, s, t) in storages_invested_available_indices(m)
                    init=0,
                )
            )
            for bi in last(benders_iteration())
            for (i,) in sp_objective_upperbound_indices(m)
        )
    )
end