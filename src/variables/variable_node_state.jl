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
    node_state_indices(filtering_options...)

A set of tuples for indexing the `node_state` variable where filtering options can be specified
for `node`, `s`, and `t`.
"""
function node_state_indices(m::Model; node=anything, stochastic_scenario=anything, t=anything, temporal_block=anything)
    node = intersect(node, SpineOpt.node(has_state=true))
    node_stochastic_time_indices(
        m; node=node, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
    )
end

function node_state_ub_as_number(; node, kwargs...)
    node_state_cap(; node=node, kwargs..., _default=NaN) * (
        + number_of_storages(; node=node, kwargs..., _default=_default_nb_of_storages(node))
        + candidate_storages(; node=node, kwargs..., _default=0)
    )
end

function node_state_ub_as_call(; node, kwargs...)
    node_state_cap[(node=node, kwargs..., _default=NaN)] * (
        + number_of_storages[(node=node, kwargs..., _default=_default_nb_of_storages(node))]
        + Call(something, [candidate_storages[(node=node, kwargs..., _default=0)], 0])
    )
end

_default_nb_of_storages(n) = is_candidate(node=n) ? 0 : 1

"""
    add_variable_node_state!(m::Model)

Add `node_state` variables to model `m`.
"""
function add_variable_node_state!(m::Model)
    add_variable!(
        m,
        :node_state,
        node_state_indices;
        lb=node_state_min,
        ub=FlexParameter(node_state_ub_as_number, node_state_ub_as_call),
        fix_value=fix_node_state,
        initial_value=initial_node_state,
    )
end
