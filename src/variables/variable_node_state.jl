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
function node_state_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    node = intersect(node, SpineOpt.node(has_state=true))
    (
        (node=n, stochastic_scenario=s, t=t)
        for (n, s, t) in node_stochastic_time_indices(
            m; node=node, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

function node_state_lb(m; node, kwargs...)
    node_state_lower_limit(m; node=node, kwargs...) * (
        + number_of_storages(m; node=node, kwargs..., _default=_default_nb_of_storages(node))
    )
end

function node_state_ub(m; node, kwargs...)
    node_state_capacity(m; node=node, kwargs..., _default=NaN) * (
        + number_of_storages(m; node=node, kwargs..., _default=_default_nb_of_storages(node))
        + something(candidate_storages(m; node=node, kwargs...), 0)
    )
end

function _get_delta_index(m, n, s, t_after, representative_blk, first_or_last)
    t = first_or_last(time_slice(m; temporal_block=representative_blk))
    inds = node_state_indices(m; node=n, stochastic_scenario=s, t=t)
    if isempty(inds)
        error(
            "time slice $t_after appears to be mapped to block '$representative_blk' ",
            "but node '$n' is not associated to it",
        )
    end
    only(inds)
end

"""
    add_variable_node_state!(m::Model)

Add `node_state` variables to model `m`.
"""
function add_variable_node_state!(m::Model)
    represented_t = sort!(collect(represented_time_slices(m)))
    replacement_expressions = OrderedDict(
        (node=n, stochastic_scenario=s, t=t_after) => [
            :node_state => Dict(
                (node=n, stochastic_scenario=s, t=t_before) => 1
            );
            [
                :node_state => Dict(_get_delta_index(m, n, s, t_after, blk, last) => coef)
                for (blk, coef) in representative_block_coefficients(m, t_after)
            ];
            [
                :node_state => Dict(_get_delta_index(m, n, s, t_after, blk, first) => -coef)
                for (blk, coef) in representative_block_coefficients(m, t_after)
            ];
        ]
        for (n, s, t_after) in node_state_indices(
            m; node=node(is_longterm_storage=true), temporal_block=anything, t=represented_t
        )
        for t_before in Iterators.take(
            (
                x.t
                for x in node_state_indices(
                    m; node=n, stochastic_scenario=s, temporal_block=anything, t=t_before_t(m; t_after=t_after)
                )
            ),
            1,
        )
    )
    add_variable!(
        m,
        :node_state,
        node_state_indices;
        lb=node_state_lb,
        ub=node_state_ub,
        fix_value=fix_node_state,
        initial_value=initial_node_state,
        replacement_expressions=replacement_expressions,
    )
end
