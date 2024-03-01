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
    add_constraint_connections_decommissioned_vintage!(m::Model)

Constrain connections_decommissioned_vintage by the difference in available invested connections.
"""
function add_constraint_connections_decommissioned_vintage!(m::Model)
    @fetch connections_decommissioned_vintage, connections_invested_available_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:connections_decommissioned_vintage] = Dict(
        (connection=c, stochastic_path=s, t_vintage=t_v, t=t_after) => @constraint(
            m,
            expr_sum(
                + connections_decommissioned_vintage[c, s_after, t_v, t_after]
                for (c, s_after, t_v, t_after) in connections_invested_available_vintage_indices(m; connection=c, stochastic_scenario=s, t_vintage=t_v, t=t_after);
                init=0
            )
            >=
            + expr_sum(
                + connections_invested_available_vintage[c, s_before, t_v, t_before]
                - connections_invested_available_vintage[c, s_after, t_v, t_after]
                for (c, s_after, t_v, t_after) in connections_invested_available_vintage_indices(m; connection=c, stochastic_scenario=s, t_vintage=t_v, t=t_after)
                    for (c, s_before, t_v, t_before) in connections_invested_available_vintage_indices(m; connection=c, stochastic_scenario=s, t_vintage=t_v, t=t_before_t(m;t_after=t_after))
                ;init=0,
            )
        ) for (c, s, t_v, t_after) in constraint_connections_decommissioned_vintage_indices(m)
    )
end

function constraint_connections_decommissioned_vintage_indices(m::Model)
    unique(
        (connection=c, stochastic_path=path, t_vintage=t_v, t=t)
        for (c, s, t_v, t) in connections_invested_available_vintage_indices(m)
        for path in active_stochastic_paths(_constraint_connections_decommissioned_vintage_indices(m, c, s, t))
    )
end

"""
    constraint_connections_decommissioned_vintage_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connections_decommissioned_vintage()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_connections_decommissioned_vintage_indices_filtered(m::Model; connection=anything, stochastic_path=anything, t_vintage=anything, t=anything)
    f(ind) = _index_in(ind; connection=connection, stochastic_path=stochastic_path, t_vintage=t_vintage, t=t)
    filter(f, constraint_connections_decommissioned_vintage_indices(m))
end

"""
    _constraint_connections_decommissioned_vintage_indices(m, c, s, t)

Gathers the `stochastic_scenario` indices of the `connections_mothballed_state_vintage` variable on the current and previous time slice.
"""
function _constraint_connections_decommissioned_vintage_indices(m, c, s, t)
    unique(ind.stochastic_scenario for ind in connections_invested_available_indices(m; connection=c, t=[t_before_t(m;t_after=t)...,t]))
end
