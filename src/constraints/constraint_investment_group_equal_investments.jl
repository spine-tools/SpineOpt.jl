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
    add_constraint_investment_group_equal_investments!(m::Model)

Force investment variables for first entity in the group and all other entities in the group to be equal.
"""
function add_constraint_investment_group_equal_investments!(m::Model)
    _add_constraint!(
        m,
        :investment_group_equal_investments,
        constraint_investment_group_equal_investments_indices,
        _build_constraint_investment_group_equal_investments,
    )
end

function _build_constraint_investment_group_equal_investments(m::Model, ig, e, other_e, s, t)
    @fetch (
        units_invested_available, connections_invested_available, storages_invested_available
    ) = m.ext[:spineopt].variables
    @build_constraint(
        + sum(
            units_invested_available[e, s, t]
            for (e, s, t) in units_invested_available_indices(
                m; unit=e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            connections_invested_available[e, s, t]
            for (e, s, t) in connections_invested_available_indices(
                m; connection=e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            storages_invested_available[e, s, t]
            for (e, s, t) in storages_invested_available_indices(
                m; node=e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        ==
        + sum(
            units_invested_available[other_e, s, t]
            for (other_e, s, t) in units_invested_available_indices(
                m; unit=other_e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            connections_invested_available[other_e, s, t]
            for (other_e, s, t) in connections_invested_available_indices(
                m; connection=other_e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
        + sum(
            storages_invested_available[other_e, s, t]
            for (other_e, s, t) in storages_invested_available_indices(
                m; node=other_e, stochastic_scenario=s, t=t_in_t(m; t_long=t)
            );
            init=0,
        )
    )
end

function constraint_investment_group_equal_investments_indices(m::Model)
    (
        (investment_group=ig, entity1=e, entity2=other_e, stochastic_scenario=s, t=t)
        for ig in investment_group(equal_investments=true)
        for e in _first_entity_investment_group(ig)
        for other_e in setdiff(entity_investment_group(ig), e)
        for (t, path) in t_lowest_resolution_path(
            m,
            Iterators.flatten(
                (
                    units_invested_available_indices(m; unit=[e, other_e]),
                    connections_invested_available_indices(m; connection=[e, other_e]),
                    storages_invested_available_indices(m; node=[e, other_e]),
                )
            )
        )
        for s in path
    )
end

function entity_investment_group(ig)
    vcat(
        unit__investment_group(investment_group=ig),
        connection__investment_group(investment_group=ig),
        node__investment_group(investment_group=ig)
    )
end

function _first_entity_investment_group(ig)
    entities = entity_investment_group(ig)
    isempty(entities) ? () : first(entities)
end