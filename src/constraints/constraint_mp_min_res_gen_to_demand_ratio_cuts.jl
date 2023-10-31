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
    add_constraint_mp_min_res_gen_to_demand_ratio!(m::Model)

sum (
    + res generation from subproblem
    + (units_invested_available - units_invested_available from last iteration)
    * unit_availability_factor * unit_capacity * unit_conv_cap_to_flow
) >= mp_min_res_gen_to_demand_ratio * total demand
"""
function add_constraint_mp_min_res_gen_to_demand_ratio_cuts!(m::Model)
    @fetch units_invested_available, mp_min_res_gen_to_demand_ratio_slack = m.ext[:spineopt].variables
    merge!(
        get!(m.ext[:spineopt].constraints, :mp_min_res_gen_to_demand_ratio_cuts, Dict()),
        Dict(
            (benders_iteration=bi, commodity=comm) => @constraint(
                m,
                + sum(
                    window_sum_duration(m, sp_unit_flow(unit=u, node=n, direction=d, stochastic_scenario=s), window)
                    for window in m.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in unit_stochastic_indices(m; unit=unit(is_renewable=true))
                    for (u, n, d) in unit__to_node(unit=u, node=node__commodity(commodity=comm), _compact=false);
                    init=0
                )
                + sum(
                    sum(
                        + units_invested_available[u, s, t]
                        - internal_fix_units_invested_available(unit=u, stochastic_scenario=s, t=t, _default=0)
                        for (u, s, t) in units_invested_available_indices(
                            m; unit=u, stochastic_scenario=s, t=to_time_slice(m; t=window)
                        );
                        init=0
                    )
                    * window_sum_duration(
                        m,
                        + unit_availability_factor(unit=u, stochastic_scenario=s)
                        * unit_capacity(unit=u, node=n, direction=d, stochastic_scenario=s)
                        * unit_conv_cap_to_flow(unit=u, node=n, direction=d, stochastic_scenario=s),
                        window
                    )
                    for window in m.ext[:spineopt].temporal_structure[:sp_windows]
                    for (u, s) in unit_stochastic_indices(m; unit=unit(is_renewable=true)) 
                    for (u, n, d) in unit__to_node(unit=u, node=node__commodity(commodity=comm), _compact=false);
                    init=0,
                )
                + get(mp_min_res_gen_to_demand_ratio_slack, (comm,), 0)
                >=
                + mp_min_res_gen_to_demand_ratio(commodity=comm)
                * (
                    sum(
                        window_sum_duration(m, demand(node=n, stochastic_scenario=s), window)
                        for window in m.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in node_stochastic_indices(
                            m; node=intersect(indices(demand), node__commodity(commodity=comm))
                        );
                        init=0
                    )
                    + sum(
                        window_sum_duration(
                            m,
                            fractional_demand(node=n, stochastic_scenario=s) * demand(node=ng, stochastic_scenario=s),
                            window
                        )
                        for window in m.ext[:spineopt].temporal_structure[:sp_windows]
                        for (n, s) in node_stochastic_indices(
                            m; node=intersect(indices(fractional_demand), node__commodity(commodity=comm))
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