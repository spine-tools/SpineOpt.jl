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
    node_state_indices(filtering_options...)

A set of tuples for indexing the `node_state` variable where filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_state_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything, temporal_block=anything)
    node = intersect(node, SpineOpt.node(has_storage=true))
    (
        (node=n, stochastic_scenario=s, t=t)
        for (n, s, t) in node_stochastic_time_indices(
            m; node=node, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
        if is_longterm_storage(node=n) || _is_representative(t)
    )
end

function node_state_lb(m; node, kwargs...)
    node_state_lower_limit(m; node=node, kwargs..., _default=NaN) * (
        + existing_storages(m; node=node, kwargs..., _default=_default_nb_of_storages(node))
    )
end

function node_state_ub(m; node, kwargs...)
    node_state_capacity(m; node=node, kwargs..., _default=NaN) * (
        + existing_storages(m; node=node, kwargs..., _default=_default_nb_of_storages(node))
        + something(storage_investment_count_max_cumulative(m; node=node, kwargs...), 0)
    )
end

"""
    add_variable_node_state!(m::Model)

Add `node_state` variables to model `m`.
"""
function add_variable_node_state!(m::Model)
    add_variable!(
        m,
        :node_state,
        node_state_indices;
        lb=node_state_lb,
        ub=node_state_ub,
        fix_value=storage_state_fix,
        initial_value=storage_state_initial,
    )
end
