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
function add_constraint_mp_min_res_gen_to_demand_ratio!(m::Model)
    @fetch units_invested_available = m.ext[:spineopt].variables
    current_constraint = pop!(m.ext[:spineopt].constraints, :mp_min_res_gen_to_demand_ratio, nothing)
    if current_constraint !== nothing
        for con_ref in values(current_constraint)
            delete(m, con_ref)
        end
    end
    m.ext[:spineopt].constraints[:mp_min_res_gen_to_demand_ratio] = Dict(
        (commodity=comm,) => @constraint(
            m,
            + sum(
                Iterators.filter(
                    !isnan,
                    sp_unit_flow(unit=u, node=n, direction=d, stochastic_scenario=s, t=t, _default=0)
                    for (u, n, d, s, t) in unit_flow_indices(
                        m;
                        unit=unit(is_renewable=true),
                        node=node__commodity(commodity=comm),
                        direction=direction(:to_node)
                    )
                );
                init=0
            )
            + sum(
                (
                    + units_invested_available[u, s, t]
                    - sum(
                        Iterators.filter(
                            !isnan,
                            internal_fix_units_invested_available(unit=u, stochastic_scenario=s, t=t, _default=0)
                        )
                    )
                )
                * sum(
                    Iterators.filter(
                        !isnan,
                        + unit_availability_factor(unit=u, stochastic_scenario=s, t=t_short)
                        * unit_capacity(unit=u, node=n, direction=d, stochastic_scenario=s, t=t_short)
                        * unit_conv_cap_to_flow(unit=u, node=n, direction=d, stochastic_scenario=s, t=t_short)
                        for (u, n, d, s, t_short) in unit_flow_indices(
                            m;
                            unit=u,
                            node=node__commodity(commodity=comm),
                            direction=direction(:to_node),
                            stochastic_scenario=s,
                            t=t_in_t(m; t_long=t)
                        )
                    );
                    init=0
                )
                for (u, s, t) in units_invested_available_indices(m; unit=unit(is_renewable=true));
                init=0,
            )
            >=
            + mp_min_res_gen_to_demand_ratio(commodity=comm)
            * sum(
                demand(node=n, stochastic_scenario=s, t=t, _default=0)
                for (n, s, t) in node_stochastic_time_indices(
                    m; node=intersect(indices(demand), node__commodity(commodity=comm))
                );
                init=0
            )
        )
        for comm in indices(mp_min_res_gen_to_demand_ratio)
    )
end
