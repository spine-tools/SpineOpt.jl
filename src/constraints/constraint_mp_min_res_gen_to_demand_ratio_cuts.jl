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
    add_constraint_mp_min_res_gen_to_demand_ratio_cuts!(m_mp, m)

sum (
    + res generation from subproblem
    + (units_invested_available - units_invested_available from last iteration)
    * unit_availability_factor * unit_capacity * unit_conv_cap_to_flow
) >= mp_min_res_gen_to_demand_ratio * total demand
"""
function add_constraint_mp_min_res_gen_to_demand_ratio_cuts!(m_mp, m)
    @fetch units_invested_available, mp_min_res_gen_to_demand_ratio_slack = m_mp.ext[:spineopt].variables
    benders_units_invested_available = m_mp.ext[:spineopt].downstream_outputs[:units_invested_available]
    sp_unit_flow = _val_by_ent(m, :unit_flow)
    merge!(
        get!(m_mp.ext[:spineopt].constraints, :mp_min_res_gen_to_demand_ratio_cuts, Dict()),
        Dict(
            (benders_iteration=bi, commodity=comm) => @constraint(
                m_mp,
                + sum(
                    window_sum_duration(
                        m_mp, sp_unit_flow[(unit=u, node=n, direction=d, stochastic_scenario=s)], window
                    )
                    for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in _unit_scenario(unit(is_renewable=true))
                    for (u, n, d) in unit__to_node(unit=u, node=node__commodity(commodity=comm), _compact=false);
                    init=0
                )
                + sum(
                    sum(
                        + units_invested_available[u, s, t]
                        - benders_units_invested_available[(unit=u, stochastic_scenario=s)](t=t)
                        for (u, s, t) in units_invested_available_indices(
                            m_mp; unit=u, stochastic_scenario=s, t=to_time_slice(m_mp; t=window)
                        );
                        init=0
                    )
                    * window_sum_duration(
                        m_mp,
                        + unit_availability_factor(unit=u, stochastic_scenario=s)
                        * unit_capacity(unit=u, node=n, direction=d, stochastic_scenario=s)
                        * unit_conv_cap_to_flow(unit=u, node=n, direction=d, stochastic_scenario=s),
                        window
                    )
                    for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in _unit_scenario(unit(is_renewable=true)) 
                    for (u, n, d) in unit__to_node(unit=u, node=node__commodity(commodity=comm), _compact=false);
                    init=0,
                )
                + get(mp_min_res_gen_to_demand_ratio_slack, (comm,), 0)
                >=
                + mp_min_res_gen_to_demand_ratio(commodity=comm)
                * (
                    sum(
                        window_sum_duration(m_mp, demand(node=n, stochastic_scenario=s), window)
                        for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in _node_scenario(intersect(indices(demand), node__commodity(commodity=comm)));
                        init=0
                    )
                    + sum(
                        window_sum_duration(
                            m_mp,
                            fractional_demand(node=n, stochastic_scenario=s) * demand(node=ng, stochastic_scenario=s),
                            window
                        )
                        for window in m_mp.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in _node_scenario(
                            intersect(indices(fractional_demand), node__commodity(commodity=comm))
                        )
                        for ng in groups(n);
                        init=0
                    )
                )
            )
            for bi in last(benders_iteration())
            for comm in indices(mp_min_res_gen_to_demand_ratio)
        )
    )
end

function _node_scenario(node)
    (
        (node=n, stochastic_scenario=s)
        for (n, ss) in node__stochastic_structure(node=node, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function _unit_scenario(unit)
    (
        (unit=u, stochastic_scenario=s)
        for (u, ss) in units_on__stochastic_structure(unit=unit, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function window_sum_duration(m, ts::TimeSeries, window; init=0)
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    time_slice_value_iter = (
        (TimeSlice(t1, t2; duration_unit=dur_unit), v) for (t1, t2, v) in zip(ts.indexes, ts.indexes[2:end], ts.values)
    )
    sum(v * duration(t) for (t, v) in time_slice_value_iter if iscontained(start(t), window) && !isnan(v); init=init)
end
window_sum_duration(m, x::Number, window; init=0) = x * duration(window) + init