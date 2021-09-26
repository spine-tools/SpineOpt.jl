#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
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
    add_constraint_min_nonspin_ramp_up!(m::Model)

Limit the minimum ramp at the start up of a unit.

For reserves the min non-spinning reserve ramp can be defined here.
"""
function add_constraint_min_nonspin_ramp_up!(m::Model)
    @fetch nonspin_ramp_up_unit_flow, nonspin_units_started_up = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:min_nonspin_start_up_ramp] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + sum(
                nonspin_ramp_up_unit_flow[u, n, d, s, t] for (u, n, d, s, t) in nonspin_ramp_up_unit_flow_indices(
                    m;
                    unit=u,
                    node=ng,
                    direction=d,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                )
            )
            >=
            + expr_sum(
                nonspin_units_started_up[u, n, s, t]
                * min_res_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, n, s, t) in nonspin_units_started_up_indices(
                    m;
                    unit=u,
                    node=ng,
                    stochastic_scenario=s,
                    t=t_overlaps_t(m; t=t),
                );
                init=0,
            )
        ) for (u, ng, d, s, t) in constraint_min_nonspin_ramp_up_indices(m)
    )
end

function constraint_min_nonspin_ramp_up_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t)
        for (u, ng, d) in indices(min_res_startup_ramp)
        for t in t_lowest_resolution(time_slice(m; temporal_block=members(node__temporal_block(node=members(ng)))))
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario for ind in Iterators.flatten((
                    nonspin_ramp_up_unit_flow_indices(m; unit=u, node=ng, direction=d, t=t),
                    nonspin_units_started_up_indices(m; unit=u, node=ng, t=t),
                ))
            ),
        )
    )
end

"""
    constraint_min_nonspin_ramp_up_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:min_nonspin_start_up_ramp` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_min_nonspin_ramp_up_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_nonspin_ramp_up_indices(m))
end
