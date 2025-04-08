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
    add_constraint_investment_group_minimum_entities_invested_available!(m::Model)

Force number of entities invested available in a group to be greater than the minimum.
"""
function add_constraint_investment_group_minimum_entities_invested_available!(m::Model)
    _add_constraint!(
        m,
        :investment_group_minimum_entities_invested_available,
        constraint_investment_group_minimum_entities_invested_available_indices,
        _build_constraint_investment_group_minimum_entities_invested_available,
    )
end

function _build_constraint_investment_group_minimum_entities_invested_available(m::Model, ig, s, t)
    @build_constraint(
        _group_entities_invested_available(m, ig, s, t)
        >=
        minimum_entities_invested_available(m; investment_group=ig, stochastic_scenario=s, t=t)
    )
end

function constraint_investment_group_minimum_entities_invested_available_indices(m::Model)
    (
        (investment_group=ig, stochastic_scenario=s, t=t)
        for ig in indices(minimum_entities_invested_available)
        for (s, t) in _entities_invested_available_s_t(m)
    )
end

"""
    add_constraint_investment_group_maximum_entities_invested_available!(m::Model)

Force number of entities invested available in a group to be lower than the maximum.
"""
function add_constraint_investment_group_maximum_entities_invested_available!(m::Model)
    _add_constraint!(
        m,
        :investment_group_maximum_entities_invested_available,
        constraint_investment_group_maximum_entities_invested_available_indices,
        _build_constraint_investment_group_maximum_entities_invested_available,
    )
end

function _build_constraint_investment_group_maximum_entities_invested_available(m::Model, ig, s, t)
    @build_constraint(
        _group_entities_invested_available(m, ig, s, t)
        <=
        maximum_entities_invested_available(m; investment_group=ig, stochastic_scenario=s, t=t)
    )
end

function constraint_investment_group_maximum_entities_invested_available_indices(m::Model)
    (
        (investment_group=ig, stochastic_scenario=s, t=t)
        for ig in indices(maximum_entities_invested_available)
        for (s, t) in _entities_invested_available_s_t(m)
    )
end

function _entities_invested_available_s_t(m)
    (
        (stochastic_scenario=s, t=t)
        for (t, path) in t_lowest_resolution_path(
            m,
            Iterators.flatten(
                (
                    units_invested_available_indices(m),
                    connections_invested_available_indices(m),
                    storages_invested_available_indices(m),
                )
            )
        )
        for s in path
    )
end

function _group_entities_invested_available(m, ig, s, t)
    @fetch (
        units_invested_available, connections_invested_available, storages_invested_available
    ) = m.ext[:spineopt].variables
    (
        + sum(
            units_invested_available[u, s, t]
            for (u, s, t) in units_invested_available_indices(
                m; unit=unit__investment_group(investment_group=ig), stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            connections_invested_available[conn, s, t]
            for (conn, s, t) in connections_invested_available_indices(
                m;
                connection=connection__investment_group(investment_group=ig),
                stochastic_scenario=s,
                t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            storages_invested_available[n, s, t]
            for (n, s, t) in storages_invested_available_indices(
                m; node=node__investment_group(investment_group=ig), stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
    )
end