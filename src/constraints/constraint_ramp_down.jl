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

Limit the maximum ramp of `ramp_down_unit_flow` of a `unit` or `unit_group` if the parameters
`ramp_down_limit`,`unit_capacity`,`unit_conv_cap_to_unit_flow` exist.
"""
function add_constraint_ramp_down!(m::Model)
    @fetch units_on, units_started_up, units_shut_down, ramp_down_unit_flow, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:ramp_down] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + sum(
                ramp_down_unit_flow[u, n, d, s, t] * duration(t)
                for (u, n, d, s, t) in ramp_down_unit_flow_indices(
                    m; unit=u, node=ng, direction=d, t=t_in_t(m; t_long=t), stochastic_scenario=s
                )
            )
            <=
            + sum(
                (
                    (
                        + units_on[u, s, t1] - units_started_up[u, s, t1]
                        - expr_sum(
                            + nonspin_units_shut_down[u, n, s, t1]
                            for (u, n, s, t1) in nonspin_units_shut_down_indices(m; unit=u, stochastic_scenario=s, t=t1)
                            if is_reserve_node(node=n) && downward_reserve(node=n);
                            init=0,
                        )
                    )
                    * ramp_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                    + (
                        max_shutdown_ramp[
                            (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)
                        ]==nothing ? units_shut_down[u, s, t1] : nothing
                    )
                    # A functional term to take care of the shut down ramps 
                    # for the case where max_shutdown_ramp is not defined (constraint_max_shut_down_ramp not in use).
                    # Cautions must be kept that it simulates constraint_max_shut_down_ramp with max_shutdown_ramp=1.
                )
                * min(duration(t), duration(t1))
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t))
            )
            * duration(t) ## [ramp_down_limit]=MW/h
        )
        for (u, ng, d, s, t) in constraint_ramp_down_indices(m)
    )
end

function constraint_ramp_down_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(ramp_down_limit)
        for (t, path) in t_lowest_resolution_path(
            m, vcat(units_on_indices(m; unit=u), ramp_down_unit_flow_indices(m; unit=u, node=ng, direction=d))
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
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ramp_down_indices(m))
end
