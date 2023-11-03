#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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
    add_constraint_ramp_down!(m::Model)

Limit the decrease of `unit_flow` between consecutive time steps according
to the `shut_down_limit` and `ramp_down_limit` parameter values.
"""
function add_constraint_ramp_down!(m::Model)
    @fetch units_on, units_shut_down, unit_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:ramp_down] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + expr_sum(
                + unit_flow[u, n, d, s, t] * duration(t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_before
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            - expr_sum(
                + unit_flow[u, n, d, s, t] * duration(t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_after
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t] * duration(t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_after
                )
                if is_reserve_node(node=n) && downward_reserve(node=n);
                init=0,
            )
            <=
            + (
                + expr_sum(
                    (
                        + (
                            + _shut_down_limit(u, ng, d, s, t0, t_after)
                            - _minimum_operating_point(u, ng, d, s, t0, t_after)
                            - _ramp_down_limit(u, ng, d, s, t0, t_after)
                        )
                        * units_shut_down[u, s, t]
                        - _minimum_operating_point(u, ng, d, s, t0, t_after)
                        * units_on[u, s, t]
                    )
                    * min(duration(t), duration(t_after))
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_after));
                    init=0
                )
                + expr_sum(
                    + (_minimum_operating_point(u, ng, d, s, t0, t_after) + _ramp_down_limit(u, ng, d, s, t0, t_after))
                    * units_on[u, s, t] * min(duration(t), duration(t_before))
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_before));
                    init=0
                )
            )
            * _unit_flow_capacity(u, ng, d, s, t0, t_after)
        )
        for (u, ng, d, s, t_before, t_after) in constraint_ramp_down_indices(m)
    )
end

function _shut_down_limit(u, ng, d, s, t0, t)
    shut_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function _ramp_down_limit(u, ng, d, s, t0, t)
    ramp_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function constraint_ramp_down_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in Iterators.flatten((indices(ramp_down_limit), indices(shut_down_limit)))
        for (ng, t_before, t_after) in node_dynamic_time_indices(m; node=ng)
        for path in active_stochastic_paths(
            m,
            [
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=[t_before, t_after]);
                units_on_indices(m; unit=u, t=[t_before, t_after])
            ]
        )
    )
end

"""
    constraint_ramp_down_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:ramp_down` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ramp_down_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    function f(ind)
        _index_in(
            ind;
            unit=unit,
            node=node,
            direction=direction,
            stochastic_path=stochastic_path,
            t_before=t_before,
            t_after=t_after,
        )
    end

    filter(f, constraint_ramp_down_indices(m))
end
