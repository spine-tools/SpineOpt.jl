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

@doc raw"""
Delta

"""
function add_constraint_longterm_node_state_trajectory!(m::Model)
    _add_constraint!(
        m,
        :longterm_node_state_trajectory,
        constraint_longterm_node_state_trajectory_indices,
        _build_constraint_longterm_node_state_trajectory,
    )
end

function _build_constraint_longterm_node_state_trajectory(m::Model, n, s, t_before, t_after)
    @fetch longterm_node_state = m.ext[:spineopt].variables
    @build_constraint(
        + longterm_node_state[n, s, t_after]
        ==
        + longterm_node_state[n, s, t_before]
        + sum(coef * _block_delta(m, n, s, blk) for (blk, coef) in representative_block_coefficients(m, t_after))
    )
end

function _block_delta(m, n, s, blk)
    last_t = last(time_slice(m; temporal_block=blk))
    first_t = only(time_slice(m; temporal_block=block__starting_point(temporal_block1=blk)))
    @fetch node_state = m.ext[:spineopt].variables
    (
        + sum(node_state[n, s, t] for (n, s, t) in node_state_indices(m; node=n, stochastic_scenario=s, t=last_t))
        - sum(node_state[n, s, t] for (n, s, t) in node_state_indices(m; node=n, stochastic_scenario=s, t=first_t))
    )
end

function constraint_longterm_node_state_trajectory_indices(m::Model)
    (
        (node=n, stochastic_scenario=s, t_before=t_before, t_after=t_after)
        for (n, s, t_after) in longterm_node_state_indices(m)
        for t_before in Iterators.take(
            (
                x.t
                for x in longterm_node_state_indices(
                    m; node=n, stochastic_scenario=s, t=t_before_t(m; t_after=t_after)
                )
            ),
            1,
        )
    )
end