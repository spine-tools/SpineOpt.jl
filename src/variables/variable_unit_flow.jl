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
    unit_flow_indices(
        unit=anything,
        node=anything,
        direction=anything,
        s=anything
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `unit_flow` variable where the keyword arguments act as filters
for each dimension.
"""
function unit_flow_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = members(unit)
    node = members(node)
    (
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u, n, d) in unit__node__direction(unit=unit, node=node, direction=direction, _compact=false)
        for (n, s, t) in node_stochastic_time_indices(
            m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

function unit_flow_ub(m; unit, node, direction, kwargs...)
    any(
        realize(unit_flow_capacity(m; unit=unit, node=ng, direction=direction, kwargs..., _strict=false)) !== nothing
        for ng in groups(node)
    ) && return NaN
    realize(
        unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _strict=false)
    ) === nothing && return NaN
    unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _default=NaN) * (
        + number_of_units(m; unit=unit, kwargs..., _default=1)
        + something(candidate_units(m; unit=unit, kwargs...), 0)
    )
end

function _fix_ratio_out_in_unit_flow(m, u, n_to, n_from, s, t, fix_ratio)
    if fix_ratio == fix_ratio_out_in_unit_flow
        fix_ratio(m; unit=u, node1=n_to, node2=n_from, stochastic_scenario=s, t=t)
    elseif fix_ratio == fix_ratio_in_out_unit_flow
        _div_or_zero(1, fix_ratio(m; unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, t=t))
    end
end

function _fix_units_on_coeff_out_in(m, u, n_to, n_from, s, t, fix_ratio)
    if fix_ratio == fix_ratio_out_in_unit_flow
        fix_units_on_coefficient_out_in(m; unit=u, node1=n_to, node2=n_from, stochastic_scenario=s, t=t, _default=0)
    elseif fix_ratio == fix_ratio_in_out_unit_flow
        - _div_or_zero(
            fix_units_on_coefficient_in_out(
                m; unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, t=t, _default=0
            ),
            fix_ratio(m; unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, t=t),
        )
    end
end

_div_or_zero(x, y) = iszero(y) ? zero(y) : x / y

function _signed_unit_start_flow(m, u, n_to, n_from, s, t, fix_ratio)
    if fix_ratio == fix_ratio_out_in_unit_flow
        - unit_start_flow(m; unit=u, node1=n_to, node2=n_from, stochastic_scenario=s, t=t, _default=0)
    elseif fix_ratio == fix_ratio_in_out_unit_flow
        - _div_or_zero(
            unit_start_flow(m; unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, t=t, _default=0),
            fix_ratio(m; unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, t=t),
        )
    end
end

function _has_simple_fix_ratio_unit_flow(n1, n2, fix_ratio)
    _similar(n1, n2) && fix_ratio in (fix_ratio_out_in_unit_flow, fix_ratio_in_out_unit_flow)
end

"""
    add_variable_unit_flow!(m::Model)

Add `unit_flow` variables to model `m`.
"""
function add_variable_unit_flow!(m::Model)
    d_to, d_from = direction(:to_node), direction(:from_node)
    replacement_expressions = Dict(
        (unit=u, node=n_to, direction=d_to, stochastic_scenario=s, t=t) => Dict(
            :unit_flow => (
                (unit=u, node=n_from, direction=d_from, stochastic_scenario=s, t=t),
                _fix_ratio_out_in_unit_flow(m, u, n_to, n_from, s, t, fix_ratio),
            ),
            :units_on => (
                (unit=u, stochastic_scenario=s, t=t), _fix_units_on_coeff_out_in(m, u, n_to, n_from, s, t, fix_ratio)
            ),
            :units_started_up => (
                (unit=u, stochastic_scenario=s, t=t), _signed_unit_start_flow(m, u, n_to, n_from, s, t, fix_ratio)
            ),
        )
        for (u, n_to, n_from, fix_ratio) in Iterators.flatten(
            (
                (
                    (u, n_to, n_from, fix_ratio_out_in_unit_flow)
                    for (u, n_to, n_from) in indices(fix_ratio_out_in_unit_flow)
                ),
                (
                    (u, n_to, n_from, fix_ratio_in_out_unit_flow)
                    for (u, n_from, n_to) in indices(fix_ratio_in_out_unit_flow)
                ),
            )
        )
        if _similar(n_to, n_from)
        for (_n, s, t) in node_stochastic_time_indices(m; node=n_to)
    )
    add_variable!(
        m,
        :unit_flow,
        unit_flow_indices;
        lb=min_unit_flow,
        ub=unit_flow_ub,
        fix_value=fix_unit_flow,
        initial_value=initial_unit_flow,
        non_anticipativity_time=unit_flow_non_anticipativity_time,
        non_anticipativity_margin=unit_flow_non_anticipativity_margin,
        replacement_expressions=replacement_expressions,
    )
end
