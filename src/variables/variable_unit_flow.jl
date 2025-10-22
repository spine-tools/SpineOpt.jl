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
    (
        realize(unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _strict=false)) === nothing
        || has_online_variable(unit=unit)
        || members(node) != [node]
    ) && return NaN
    unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _default=NaN) * (
        + number_of_units(m; unit=unit, kwargs..., _default=_default_nb_of_units(unit))
        + something(candidate_units(m; unit=unit, kwargs...), 0)
    )
end

#=
Replacement expressions
Direct:
    unit_flow[u, n1, d1]
    ==
    fix_ratio(u, n1, n2) * unit_flow[u, n2, d2]
    + fix_units_on_coeff(u, n1, n2) * units_on[u]
    + startflow_sign(fix_ratio) * unit_start_flow(u, n1, n2) * units_started_up[u]

Inverse:
    unit_flow[u, n1, d1]
    ==
    (1 / fix_ratio(u, n2, n1)) * unit_flow[u, n2, d2]
    - (fix_units_on_coeff(u, n2, n1) / fix_ratio(u, n2, n1)) * units_on[u]
    - (startflow_sign(fix_ratio) * unit_start_flow(u, n2, n1) / fix_ratio(u, n2, n1)) * units_started_up[u]
=#
function _fix_ratio_unit_flow(m, u, n1, n2, s, t, fix_ratio, direct)
    if direct
        fix_ratio(m; unit=u, node1=n1, node2=n2, stochastic_scenario=s, t=t)
    else
        _div_or_zero(1, fix_ratio(m; unit=u, node1=n2, node2=n1, stochastic_scenario=s, t=t))
    end
end

function _fix_units_on_coeff(m, u, n1, n2, s, t, fix_ratio, direct)
    fix_units_on_coeff = _ratio_to_units_on_coeff(fix_ratio)
    if direct
        fix_units_on_coeff(m; unit=u, node1=n1, node2=n2, stochastic_scenario=s, t=t, _default=0)
    else
        - _div_or_zero(
            fix_units_on_coeff(m; unit=u, node1=n2, node2=n1, stochastic_scenario=s, t=t, _default=0),
            fix_ratio(m; unit=u, node1=n2, node2=n1, stochastic_scenario=s, t=t),
        )
    end
end

function _signed_unit_start_flow(m, u, n1, n2, s, t, fix_ratio, direct)
    sign = _ratio_to_start_flow_sign(fix_ratio)
    iszero(sign) && return 0
    if direct
        sign * unit_start_flow(m; unit=u, node1=n1, node2=n2, stochastic_scenario=s, t=t, _default=0)
    else
        - sign * _div_or_zero(
            unit_start_flow(m; unit=u, node1=n2, node2=n1, stochastic_scenario=s, t=t, _default=0),
            fix_ratio(m; unit=u, node1=n2, node2=n1, stochastic_scenario=s, t=t),
        )
    end
end

function _has_simple_fix_ratio_unit_flow(m, u, n1, d1, n2, d2, fix_ratio)
    _similar(n1, n2) && fix_ratio in _fix_unit_flow_ratios() &&
        isempty(unit_flow_op_indices(m; unit=u, node=n1, direction=d1)) &&
        isempty(unit_flow_op_indices(m; unit=u, node=n2, direction=d2))
end

function _fix_unit_flow_ratios()
    (fix_ratio_out_in_unit_flow, fix_ratio_in_out_unit_flow, fix_ratio_out_out_unit_flow, fix_ratio_in_in_unit_flow)
end

"""
    add_variable_unit_flow!(m::Model)

Add `unit_flow` variables to model `m`.
"""
function add_variable_unit_flow!(m::Model)
    fix_ratio_d1_d2 = ((r, _ratio_to_d1_d2(r)...) for r in _fix_unit_flow_ratios())
    replacement_expressions = OrderedDict(
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t) => [
            :unit_flow => Dict(
                (
                    unit=u,
                    node=n_ref,
                    direction=d_ref,
                    stochastic_scenario=s,
                    t=t,
                ) => _fix_ratio_unit_flow(m, u, n, n_ref, s, t, fix_ratio, direct)
            ),
            :units_on => Dict(
                (unit=u, stochastic_scenario=s, t=t) => _fix_units_on_coeff(m, u, n, n_ref, s, t, fix_ratio, direct)
            ),
            :units_started_up => Dict(
                (unit=u, stochastic_scenario=s, t=t) => /(
                    _signed_unit_start_flow(m, u, n, n_ref, s, t, fix_ratio, direct), duration(t)
                )
            ),
        ]
        for (u, n_ref, d_ref, n, d, fix_ratio, direct) in _related_flows(fix_ratio_d1_d2)
        if _has_simple_fix_ratio_unit_flow(m, u, n, d, n_ref, d_ref, fix_ratio)
        for (_n, s, t) in node_stochastic_time_indices(m; node=n_ref)
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
