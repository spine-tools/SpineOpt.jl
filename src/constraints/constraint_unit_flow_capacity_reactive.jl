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
    add_constraint_unit_flow_capacity_reactive!(m::Model)

Limit the maximum in/out `unit_flow_reactive` of a `unit` for all `unit_capacity_reactive` indices.

"""
function add_constraint_unit_flow_capacity_reactive!(m::Model)
    @fetch unit_flow_reactive, units_on = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_flow_capacity_reactive] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            expr_sum(
                unit_flow_reactive[u, n, d, s, t] * duration(t)
                for (u, n, d, s, t) in unit_flow_reactive_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t)
                )
                if !is_non_spinning(node=n);
                init=0,
            )
            <=
            + expr_sum(
                units_on[u, s, t1]
                * min(duration(t1), duration(t))
                * unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity_reactive[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )           
        )
        for (u, ng, d, s, t) in constraint_unit_flow_capacity_reactive_indices(m)
    )
end

function constraint_unit_flow_capacity_reactive_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(unit_capacity_reactive)
        for (t, path) in t_lowest_resolution_path(
            m, vcat(unit_flow_reactive_indices(m; unit=u, node=ng, direction=d), units_on_indices(m; unit=u))
        )
    )
end