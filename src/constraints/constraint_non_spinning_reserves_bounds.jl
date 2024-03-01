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
    add_constraint_non_spinning_reserves_lower_bound!(m::Model)

"""
function add_constraint_non_spinning_reserves_lower_bound!(m::Model)
    @fetch unit_flow, nonspin_units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:non_spinning_reserves_lower_bound] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            sum(
                + minimum_operating_point[
                    (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_over, _default=0)
                ]
                * unit_capacity[
                    (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_over)
                ]
                * _switch(d; from_node=nonspin_units_shut_down, to_node=nonspin_units_started_up)[u, n, s, t_over]
                * min(duration(t), duration(t_over))
                for (u, n, s, t_over) in _switch(
                    d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices
                )(m; unit=u, node=ng, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0
            )
            <=
            sum(
                unit_flow[u, n, d, s, t_short] * duration(t_short)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                )
                if is_reserve_node(node=n) && is_non_spinning(node=n)
                init=0
            )
        )
        for (u, ng, d, s, t) in constraint_non_spinning_reserves_bounds_indices(m)
    )
end

function _add_constraint_non_spinning_reserves_upper_bound!(m::Model, limit::Parameter)
    @fetch unit_flow, nonspin_units_started_up, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    name = Dict(
        start_up_limit => :non_spinning_reserves_start_up_upper_bound,
        shut_down_limit => :non_spinning_reserves_shut_down_upper_bound,
    )[limit]
    m.ext[:spineopt].constraints[name] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            sum(
                unit_flow[u, n, d, s, t_short] * duration(t_short)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                )
                if is_reserve_node(node=n) && is_non_spinning(node=n)
                init=0
            )
            <=
            sum(
                + limit[
                    (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_over, _default=1)
                ]
                * unit_capacity[
                    (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_over)
                ]
                * _switch(d; from_node=nonspin_units_shut_down, to_node=nonspin_units_started_up)[u, n, s, t_over]
                * min(duration(t), duration(t_over))
                for (u, n, s, t_over) in _switch(
                    d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices
                )(m; unit=u, node=ng, stochastic_scenario=s, t=t_overlaps_t(m; t));
                init=0
            )
        )
        for (u, ng, d, s, t) in constraint_non_spinning_reserves_bounds_indices(m)
    )
end

function add_constraint_non_spinning_reserves_start_up_upper_bound!(m::Model)
    _add_constraint_non_spinning_reserves_upper_bound!(m, start_up_limit)
end

function add_constraint_non_spinning_reserves_shut_down_upper_bound!(m::Model)
    _add_constraint_non_spinning_reserves_upper_bound!(m, shut_down_limit)
end

function constraint_non_spinning_reserves_bounds_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity)
        if any(is_reserve_node(node=n) && is_non_spinning(node=n) for n in members(ng))
        for (t, path) in t_lowest_resolution_path(
            m,
            unit_flow_indices(m; unit=u, node=ng, direction=d),
            _switch(d; from_node=nonspin_units_shut_down_indices, to_node=nonspin_units_started_up_indices)(m; unit=u)
        )
    )
end

"""
    constraint_non_spinning_reserves_bounds_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:non_spinning_units_started_up_bounds` constraint.

Uses stochastic path indices due to potentially different stochastic structures between
`unit_flow` and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_non_spinning_reserves_bounds_indices_filtered(
    m::Model; unit=anything, node=anything, direction=anything, stochastic_path=anything, t=anything
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_non_spinning_units_started_up_bounds_indices(m))
end
