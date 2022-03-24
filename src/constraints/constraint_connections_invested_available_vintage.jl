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
    add_constraint_connections_invested_available_vintage!(m::Model)

Constrain connections_invested_available_vintage by the investment lifetime of a connection and early decomissioning.
"""
function add_constraint_connections_invested_available_vintage!(m::Model)
    @fetch connections_invested_available_vintage, connections_invested, connections_early_decommissioned_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:connections_invested_available_vintage] = Dict(
        (connection=c, stochastic_path=s, t_vintage=t_v, t=t) => @constraint(
            m,
            + expr_sum(
                + connections_invested_available_vintage[c, s, t_v, t]
                for (c, s, t_v, t) in connections_invested_available_vintage_indices(m; connection=c, stochastic_scenario=s, t_vintage=t_v, t=t);
                init=0,
            )
            ==
            #FIXME: can we fix this parameter call? Currently, first needs to be added
            + expr_sum(
                    + connection_capacity_transfer_factor[(connection=c, stochastic_scenario=s_v,vintage_t=first(t_v.start),t=t)]
                    * (connections_invested[c, s_v, t_v]
                    - expr_sum(
                        connections_early_decommissioned_vintage[c, s_, t_v, t_]
                        for (c, s_, t_v, t_) in connections_invested_available_vintage_indices(
                            m;
                            connection=c,
                            stochastic_scenario=s,
                            t=to_time_slice(
                                m;
                                t=TimeSlice(
                                    start(t_v),
                                    end_(t),
                                ),
                            ),
                        );
                    init=0
                    )
                )
                for (c, s_v, t_v) in connections_invested_available_indices(
                            m;
                            connection=c,
                            stochastic_scenario=s,
                            t=t_v,
                            )
                ; init=0
                )
        ) for (c, s, t_v, t) in constraint_connections_invested_available_vintage_indices(m)
    )
end

function constraint_connections_invested_available_vintage_indices(m::Model)
    t0 = _analysis_time(m)
    unique(
        (connection=c, stochastic_path=path, t_vintage=t_v, t=t)
        for c in indices(connection_investment_tech_lifetime) for (c, s, t_v, t) in connections_invested_available_vintage_indices(m; connection=c)
        for path in active_stochastic_paths(_constraint_connections_invested_available_vintage_indices(m, c, s, t_v, t))
    )
end

"""
    constraint_connections_invested_available_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connections_invested_available_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_connections_invested_available_vintage_indices_filtered(m::Model; connection=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; connection=cnit, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_connections_invested_available_vintage_indices(m))
end

"""
    _constraint_connection_lifetime_indices(c, s, t0, t)

Gathers the `stochastic_scenario` indices of the `connections_invested_available` variable on past time slices determined
by the `connection_investment_tech_lifetime` parameter.
"""
function _constraint_connections_invested_available_vintage_indices(m, c, s, t_v, t)
    t_past_and_present = to_time_slice(
        m;
        t=TimeSlice(start(t_v), end_(t)),
    )
    unique(ind.stochastic_scenario for ind in connections_invested_available_indices(m; connection=c, t=t_past_and_present))
end
