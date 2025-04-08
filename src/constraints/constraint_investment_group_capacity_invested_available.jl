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
    add_constraint_investment_group_minimum_capacity_invested_available!(m::Model)

Force capacity invested available in a group to be greater than the minimum.
"""
function add_constraint_investment_group_minimum_capacity_invested_available!(m::Model)
    _add_constraint!(
        m,
        :investment_group_minimum_capacity_invested_available,
        constraint_investment_group_minimum_capacity_invested_available_indices,
        _build_constraint_investment_group_minimum_capacity_invested_available,
    )
end

function _build_constraint_investment_group_minimum_capacity_invested_available(m::Model, ig, s, t)
    @build_constraint(
        _group_capacity_invested_available(m, ig, s, t)
        >=
        minimum_capacity_invested_available(m; investment_group=ig, stochastic_scenario=s, t=t)
    )
end

function constraint_investment_group_minimum_capacity_invested_available_indices(m::Model)
    (
        (investment_group=ig, stochastic_scenario=s, t=t)
        for ig in indices(minimum_capacity_invested_available)
        for (s, t) in _capacity_entities_invested_available_s_t(m)
    )
end

"""
    add_constraint_investment_group_maximum_capacity_invested_available!(m::Model)

Force capacity invested available in a group to be lower than the maximum.
"""
function add_constraint_investment_group_maximum_capacity_invested_available!(m::Model)
    _add_constraint!(
        m,
        :investment_group_maximum_capacity_invested_available,
        constraint_investment_group_maximum_capacity_invested_available_indices,
        _build_constraint_investment_group_maximum_capacity_invested_available,
    )
end

function _build_constraint_investment_group_maximum_capacity_invested_available(m::Model, ig, s, t)
    @build_constraint(
        _group_capacity_invested_available(m, ig, s, t)
        <=
        maximum_capacity_invested_available(m; investment_group=ig, stochastic_scenario=s, t=t)
    )
end

function constraint_investment_group_maximum_capacity_invested_available_indices(m::Model)
    (
        (investment_group=ig, stochastic_scenario=s, t=t)
        for ig in indices(maximum_capacity_invested_available)
        for (s, t) in _capacity_entities_invested_available_s_t(m)
    )
end

function _capacity_entities_invested_available_s_t(m)
    (
        (stochastic_scenario=s, t=t)
        for (t, path) in t_lowest_resolution_path(
            m, Iterators.flatten((units_invested_available_indices(m), connections_invested_available_indices(m)))
        )
        for s in path
    )
end

function _group_capacity_invested_available(m, ig, s, t)
    @fetch units_invested_available, connections_invested_available = m.ext[:spineopt].variables
    (
        + sum(
            + units_invested_available[u, s, t]
            * unit_capacity(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
            for (u, s, t) in units_invested_available_indices(
                m; unit=unit__investment_group(investment_group=ig), stochastic_scenario=s, t=t_in_t(m; t_long=t)
            )
            for (u, n, d) in Iterators.flatten(
                (
                    indices(
                        unit_capacity;
                        unit=u,
                        node=unit__from_node__investment_group(unit=u, investment_group=ig),
                        direction=direction(:from_node),
                    ),
                    indices(
                        unit_capacity;
                        unit=u,
                        node=unit__to_node__investment_group(unit=u, investment_group=ig),
                        direction=direction(:to_node),
                    ),
                )
            );
            init=0,
        )
        + sum(
            + connections_invested_available[conn, s, t]
            * connection_capacity(m; connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
            for (conn, s, t) in connections_invested_available_indices(
                m;
                connection=connection__investment_group(investment_group=ig),
                stochastic_scenario=s,
                t=t_in_t(m; t_long=t)
            )
            for (conn, n, d) in Iterators.flatten(
                (
                    indices(
                        connection_capacity;
                        connection=conn,
                        node=connection__from_node__investment_group(connection=conn, investment_group=ig),
                        direction=direction(:from_node),
                    ),
                    indices(
                        connection_capacity;
                        connection=conn,
                        node=connection__to_node__investment_group(connection=conn, investment_group=ig),
                        direction=direction(:to_node),
                    ),
                )
            );
            init=0,
        )
    )
end