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
    temporal_block=temporal_block(is_representative=true),
)
    to_node = SpineOpt.direction(:to_node)
    from_node = SpineOpt.direction(:from_node)
    unit = members(unit)
    node = members(node)
    unit__node__to_node = if in(to_node, direction)
        (
            (unit=u, node=n, direction=to_node, stochastic_scenario=s, t=t)
            for (u, n) in unit__to_node(unit=unit, node=node, _compact=false)
            for (n, s, t) in node_stochastic_time_indices(
                m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
            )
        )
    else
        ()
    end
    unit__node__from_node = if in(from_node, direction)
        (
            (unit=u, node=n, direction=from_node, stochastic_scenario=s, t=t)
            for (n, u) in node__to_unit(node=node, unit=unit, _compact=false)
            for (n, s, t) in node_stochastic_time_indices(
                m; node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
            )
        )
    else
        ()
    end
    return Iterators.flatten((unit__node__to_node, unit__node__from_node))
end

function unit_flow_ub(m; unit, node, direction, kwargs...)
    (
        realize(unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _strict=false)) === nothing
        || has_online_variable(unit=unit)
        || members(node) != [node]
    ) && return NaN
    unit_flow_capacity(m; unit=unit, node=node, direction=direction, kwargs..., _default=NaN) * (
        + existing_units(m; unit=unit, kwargs..., _default=_default_nb_of_units(unit))
        + something(investment_count_max_cumulative(m; unit=unit, kwargs...), 0)
    )
end

function _split_flows(u1, n1, d1, u2, n2, d2)
    flow1 = (d1 == direction(:to_node)) ? (unit1=u1, node1=n1) : (node1=n1, unit1=u1)
    flow2 = (d2 == direction(:to_node)) ? (unit2=u2, node2=n2) : (node2=n2, unit2=u2)
    return flow1, flow2
end

function _inverse_flow(flow)
    key = first(keys(flow))
    if key == :unit1
        return (unit2=flow.unit1, node2=flow.node1)
    elseif key == :node1
        return (node2=flow.node1, unit2=flow.unit1)
    elseif key == :unit2
        return (unit1=flow.unit2, node1=flow.node2)
    else
        return (node1=flow.node2, unit1=flow.unit2)
    end
end

#=
Replacement expressions
Direct:
    unit_flow[u, n1, d1]
    ==
    fix_ratio(u, n1, n2) * unit_flow[u, n2, d2]
    + fix_units_on_coeff(u, n1, n2) * units_on[u]
    + startflow_sign(fix_ratio) * flow_ratio_start_flow(u, n1, n2) * units_started_up[u]

Inverse:
    unit_flow[u, n1, d1]
    ==
    (1 / fix_ratio(u, n2, n1)) * unit_flow[u, n2, d2]
    - (fix_units_on_coeff(u, n2, n1) / fix_ratio(u, n2, n1)) * units_on[u]
    - (startflow_sign(fix_ratio) * flow_ratio_start_flow(u, n2, n1) / fix_ratio(u, n2, n1)) * units_started_up[u]
=#
function _fix_ratio_unit_flow(m, u1, n1, d1, u2, n2, d2, s, t, fix_ratio, direct)
    flow1, flow2 = _split_flows(u1, n1, d1, u2, n2, d2)
    if direct
        fix_ratio(
            m; 
            flow1...,
            flow2...,
            stochastic_scenario=s, t=t
        )
    else
        _div_or_zero(
            1, 
            fix_ratio(
                m; 
                _inverse_flow(flow2)..., 
                _inverse_flow(flow1)..., 
                stochastic_scenario=s, t=t
            )
        )
    end
end

function _fix_units_on_coeff(m, u1, n1, d1, u2, n2, d2, s, t, fix_ratio, direct)
    flow1, flow2 = _split_flows(u1, n1, d1, u2, n2, d2)
    fix_units_on_coeff = _ratio_to_units_on_coeff(fix_ratio)
    if direct
        fix_units_on_coeff(
            m; 
            flow1..., 
            flow2..., 
            stochastic_scenario=s, t=t,
            _default=0
        )
    else
        - _div_or_zero(
            fix_units_on_coeff(
                m; 
                _inverse_flow(flow2)...,
                _inverse_flow(flow1)...,
                stochastic_scenario=s, t=t,
                _default=0
            ),
            fix_ratio(
                m; 
                _inverse_flow(flow2)...,
                _inverse_flow(flow1)...,
                stochastic_scenario=s, t=t
            ),
        )
    end
end

function _signed_flow_ratio_start_flow(m, u1, n1, d1, u2, n2, d2, s, t, fix_ratio, direct)
    flow1, flow2 = _split_flows(u1, n1, d1, u2, n2, d2)
    sign = _ratio_and_directions_to_start_flow_sign(fix_ratio, d1, d2)
    iszero(sign) && return 0
    if direct
        sign * flow_ratio_start_flow(
            m; 
            flow1..., 
            flow2..., 
            stochastic_scenario=s, t=t,
            _default=0
        )
    else
        - sign * _div_or_zero(
            flow_ratio_start_flow(
                m; 
                _inverse_flow(flow2)..., 
                _inverse_flow(flow1)..., 
                stochastic_scenario=s, t=t,
                _default=0
            ),
            fix_ratio(
                m; 
                _inverse_flow(flow2)..., 
                _inverse_flow(flow1)..., 
                stochastic_scenario=s, t=t
            ),
        )
    end
end

function _has_simple_fix_ratio_unit_flow(m, u1, n1, d1, u2, n2, d2, fix_ratio)
    _similar(n1, n2) && fix_ratio in (flow_ratio_equality_coefficient, ) &&
        isempty(unit_flow_op_indices(m; unit=u1, node=n1, direction=d1)) &&
        isempty(unit_flow_op_indices(m; unit=u2, node=n2, direction=d2))
end

function _related_unit_flows(fix_ratio)
    flows_by_ref_flow = OrderedDict()
    fix_ratio_direct = Dict()
    for flows in indices(fix_ratio)
        d1 = _flow_direction(flows)
        d2 = _flow_direction(flows, 3)
        # Only keep flows where the unit is the same, add a test if they are not the same
        flows.unit1 == flows.unit2 || continue
        _similar(flows.node1, flows.node2) || continue
        f1 = (flows.unit1, flows.node1, d1)
        f2 = (flows.unit2, flows.node2, d2)
        push!(get!(flows_by_ref_flow, f2, Set()), f1)
        push!(get!(flows_by_ref_flow, f1, Set()), f2)
        fix_ratio_direct[flows.unit1, flows.node2, d2, flows.node1, d1] = (fix_ratio, true)
        fix_ratio_direct[flows.unit1, flows.node1, d1, flows.node2, d2] = (fix_ratio, false)
    end
    sort!(flows_by_ref_flow; by=(k -> length(flows_by_ref_flow[k])), rev=true)
    seen_flows = Set()
    for (ref, flows) in flows_by_ref_flow
        setdiff!(flows, seen_flows)
        push!(seen_flows, ref)
        union!(seen_flows, flows)
    end
    lt(flow1, flow2) = flow2 in get(flows_by_ref_flow, flow1, ())
    sort!(flows_by_ref_flow; lt=lt)
    (
        (u1, n_ref, d_ref, n, d, fix_ratio_direct[u1, n_ref, d_ref, n, d]...)
        for ((u1, n_ref, d_ref), flows) in flows_by_ref_flow
        for (_u, n, d) in flows
    )
end

"""
    add_variable_unit_flow!(m::Model)

Add `unit_flow` variables to model `m`.
"""
function add_variable_unit_flow!(m::Model)
    replacement_expressions = OrderedDict(
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t) => [
            :unit_flow => Dict(
                (
                    unit=u,
                    node=n_ref,
                    direction=d_ref,
                    stochastic_scenario=s,
                    t=t,
                ) => _fix_ratio_unit_flow(m, u, n, d, u, n_ref, d_ref, s, t, fix_ratio, direct)
            ),
            :units_on => Dict(
                (
                    unit=u, stochastic_scenario=s, t=t
                ) => _fix_units_on_coeff(m, u, n, d, u, n_ref, d_ref, s, t, fix_ratio, direct)
            ),
            :units_started_up => Dict(
                (
                    unit=u, stochastic_scenario=s, t=t
                ) => /(
                    _signed_flow_ratio_start_flow(m, u, n, d, u, n_ref, d_ref, s, t, fix_ratio, direct), duration(t)
                )
            ),
        ]
        for (u, n_ref, d_ref, n, d, fix_ratio, direct) in _related_unit_flows(flow_ratio_equality_coefficient)
        if _has_simple_fix_ratio_unit_flow(m, u, n, d, u, n_ref, d_ref, fix_ratio)
        for (_n, s, t) in node_stochastic_time_indices(m; node=n_ref)
    )
    add_variable!(
        m,
        :unit_flow,
        unit_flow_indices;
        lb=flow_limits_min,
        ub=unit_flow_ub,
        fix_value=flow_limits_fix,
        initial_value=flow_limits_initial,
        non_anticipativity_time=unit_flow_non_anticipativity_time,
        non_anticipativity_margin=unit_flow_non_anticipativity_margin,
        replacement_expressions=replacement_expressions,
    )
end
