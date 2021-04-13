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
    add_constraint_connections_invested_transition!(m::Model)

Ensure consistency between the variables `connections_invested_available`, `connections_invested` and
`connections_decommissioned`.
"""
function add_constraint_connections_invested_transition!(m::Model)
    @fetch connections_invested_available, connections_invested, connections_decommissioned = m.ext[:variables]
    m.ext[:constraints][:connections_invested_transition] = Dict(
        (connection=conn, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            expr_sum(
                + connections_invested_available[conn, s, t_after] - connections_invested[conn, s, t_after]
                + connections_decommissioned[conn, s, t_after]
                for (conn, s, t_after) in connections_invested_available_indices(
                    m;
                    connection=conn,
                    stochastic_scenario=s,
                    t=t_after,
                );
                init=0,
            )
            ==
            expr_sum(
                + connections_invested_available[conn, s, t_before]
                for (conn, s, t_before) in connections_invested_available_indices(
                    m;
                    connection=conn,
                    stochastic_scenario=s,
                    t=t_before,
                );
                init=0,
            )
        ) for (conn, s, t_before, t_after) in constraint_connections_invested_transition_indices(m)
    )
end

function constraint_connections_invested_transition_indices(m::Model)
    unique(
        (connection=conn, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (conn, t_before, t_after) in connection_investment_dynamic_time_indices(m)
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in connections_invested_available_indices(m; connection=conn, t=[t_before, t_after])
            ),
        )
    )
end

"""
    constraint_connections_invested_transition_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connections_invested_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting array.
"""
function constraint_connections_invested_transition_indices_filtered(
    m::Model;
    connection=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; connection=connection, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_connections_invested_transition_indices(m))
end
