#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    add_constraint_mp_units_invested_cut!(m_mp, m)

Adds Benders optimality cuts.
This tells the master problem the improvement of the subproblem objective value that is possible for an increase
in the number of investments.
"""
function add_constraint_mp_any_invested_cuts!(m_mp, m)
    @fetch (
        sp_objective_upperbound,
        units_invested_available,
        connections_invested_available,
        storages_invested_available
    ) = m_mp.ext[:spineopt].variables
    benders_units_invested_available = m_mp.ext[:spineopt].downstream_outputs[:units_invested_available]
    benders_connections_invested_available = m_mp.ext[:spineopt].downstream_outputs[:connections_invested_available]
    benders_storages_invested_available = m_mp.ext[:spineopt].downstream_outputs[:storages_invested_available]
    units_invested_available_mv = _val_by_ent(m, :bound_units_invested_available)
    connections_invested_available_mv = _val_by_ent(m, :bound_connections_invested_available)
    storages_invested_available_mv = _val_by_ent(m, :bound_storages_invested_available)
    merge!(
        get!(m_mp.ext[:spineopt].constraints, :mp_any_invested_cut, Dict()),
        Dict(
            (benders_iteration=current_bi, t=t) => @constraint(
                m_mp,
                + sp_objective_upperbound[t]
                >=
                + m.ext[:spineopt].extras[:sp_objective_value_bi]
                # operating cost benefit from investments in units
                + sum(
                    (
                        + units_invested_available[u, s, t]
                        - benders_units_invested_available[(unit=u, stochastic_scenario=s)](t=t)
                    )
                    * window_sum(units_invested_available_mv[(unit=u, stochastic_scenario=s)], t)
                    for (u, s, t) in units_invested_available_indices(m_mp);
                    init=0,
                )
                # operating cost benefit from investments in connections
                + sum(
                    (
                        + connections_invested_available[c, s, t]
                        - benders_connections_invested_available[(connection=c, stochastic_scenario=s)](t=t)
                    )
                    * window_sum(connections_invested_available_mv[(connection=c, stochastic_scenario=s)], t)
                    for (c, s, t) in connections_invested_available_indices(m_mp);
                    init=0,
                )
                # operating cost benefit from investments in storages
                + sum(
                    (
                        + storages_invested_available[n, s, t]
                        - benders_storages_invested_available[(node=n, stochastic_scenario=s)](t=t)
                    )
                    * window_sum(storages_invested_available_mv[(node=n, stochastic_scenario=s)], t)
                    for (n, s, t) in storages_invested_available_indices(m_mp);
                    init=0,
                )
            )
            for (t,) in sp_objective_upperbound_indices(m_mp)
        )
    )
end

function window_sum(ts::TimeSeries, window; init=0)
    sum(v for (t, v) in ts if iscontained(t, window) && !isnan(v); init=init)
end
