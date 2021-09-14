#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices if ramping is considered.
Note that equations including the variables `unit_flow` and `units_on/started_up/shut_down` always take the assumption
that the resolution of the commitment variable is lower or equal than the resolution the flow variables.

Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity_w_ramp!(m::Model)
    return
    # FIXME: MethodError: no method matching isless(::SpineInterface.OperatorCall{typeof(-)}, ::SpineInterface.IdentityCall{Float64})
    @fetch unit_flow, units_on, units_started_up, units_shut_down = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:unit_flow_capacity_w_ramp] = constraint = Dict()
    for (u, ng, d, s, t_before, t_after) in constraint_unit_flow_capacity_w_ramp_indices(m)
        cutout = first(
            end_(t_before) - start(t)
            for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_before))
        )
        if min_up_time(unit=u) != nothing && min_up_time(unit=u) > cutout
            constraint[
                (unit=u, node=ng, direction=d, stochastic_path=s, t=t_before),
            ] = @constraint(
                m,
                expr_sum(
                    + unit_flow[u, n, d, s, t_before1] * duration(t_before1)
                    for (u, n, d, s, t_before1) in unit_flow_indices(
                        m;
                        unit=u,
                        node=ng,
                        direction=d,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                )
                <=
                + expr_sum(
                    (units_on[u, s, t_before1] - units_started_up[u, s, t_before1] - units_shut_down[u, s, t_after1])
                    * min(duration(t_before1), duration(t_before))
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    ) for (u, s, t_after1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    init=0,
                )
                + expr_sum(
                    units_started_up[u, s, t_before1]
                    * min(duration(t_before1), duration(t_before))
                    * max_startup_ramp[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                )
                + expr_sum(
                    units_shut_down[u, s, t_after1]
                    * min(duration(t_after1), duration(t_before))
                    * max_shutdown_ramp[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ]
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ] for (u, s, t_after1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t = t_after);
                    # do we need t_overlap_t here?
                    init=0,
                )
            )
        else
            # Part 1
            constraint[
                (unit=u, node=ng, direction=d, stochastic_path=s, t=t_before, i=1),
            ] = @constraint(
                m,
                expr_sum(
                    + unit_flow[u, n, d, s, t] * duration(t) for (u, n, d, s, t) in unit_flow_indices(
                        m;
                        unit=u,
                        node=ng,
                        direction=d,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                )
                <=
                + expr_sum(
                    (units_on[u, s, t_before1] - units_shut_down[u, s, t_after1])
                    * min(duration(t_before1), duration(t_before))
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    ) for (u, s, t_after1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    init=0,
                ) - expr_sum(
                    units_started_up[u, s, t_before1]
                    * min(duration(t_before1), duration(t_before))
                    * max(
                        + max_shutdown_ramp[
                            (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                        ] - max_startup_ramp[
                            (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                        ],
                        0,
                    )
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                ) + expr_sum(
                    units_shut_down[u, s, t_after1]
                    * min(duration(t_after1), duration(t_after))
                    * max_shutdown_ramp[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ]
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ] for (u, s, t_after1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    # do we need t_overlap_t here?
                    init=0,
                )
            )
            # Part 2
            constraint[
                (unit=u, node=ng, direction=d, stochastic_path=s, t=t_before, i=2),
            ] = @constraint(
                m,
                expr_sum(
                    + unit_flow[u, n, d, s, t] * min(duration(t), duration(t_before))
                    for (u, n, d, s, t) in unit_flow_indices(
                        m;
                        unit=u,
                        node=ng,
                        direction=d,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                )
                <=
                + expr_sum(
                    (units_on[u, s, t_before1] - units_started_up[u, s, t_before1])
                    * min(duration(t_before1), duration(t_before))
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                ) + expr_sum(
                    units_started_up[u, s, t_before1]
                    * min(duration(t_before1), duration(t_before))
                    * max_startup_ramp[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ]
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_before),
                    ] for (u, s, t_before1) in units_on_indices(
                        m;
                        unit=u,
                        stochastic_scenario=s,
                        t=t_overlaps_t(m; t=t_before),
                    );
                    init=0,
                ) - expr_sum(
                    units_shut_down[u, s, t_after1]
                    * min(duration(t_after1), duration(t_after))
                    * max(
                        max_startup_ramp[
                            (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                        ] - max_shutdown_ramp[
                            (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                        ],
                        0,
                    )
                    * unit_capacity[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ]
                    * unit_conv_cap_to_flow[
                        (unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_after),
                    ] for (u, s, t_after1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    # do we need t_overlap_t here?
                    init=0,
                )
            )
        end
    end
end

# TODO: we should only consider the highest t_highest_resolution of either uniton or unitflow
# TODO: how to determine this especially when e.g. this "order" swaps between two timesteps/ corner case I guess?
function constraint_unit_flow_capacity_w_ramp_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in indices(max_shutdown_ramp)
        for t_after in time_slice(m; temporal_block=units_on__temporal_block(unit=u))
        for t_before in t_lowest_resolution(
            time_slice(
                m;
                temporal_block=members(node__temporal_block(node=members(ng))),
                t=t_before_t(m, t_after=t_after),
            ),
        ) for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in _constraint_unit_flow_capacity_w_ramp_indices(m, u, ng, d, t_before, t_after)
            ),
        )
    )
end

"""
    constraint_unit_flow_capacity_w_ramp_indices_filtered(m::Model; filtering_options...)

Forms the stochastic indexing Array for the `:unit_flow_capacity` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and `units_on`
variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_flow_capacity_w_ramp_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    function f(ind)
        _index_in(
            ind;
            unit=unit,
            node=node,
            direction=direction,
            stochastic_path=stochastic_path,
            t_before=t_before,
            t_after=t_after,
        )
    end
    filter(f, constraint_unit_flow_capacity_w_ramp_indices(m))
end

"""
    _constraint_unit_flow_capacity_w_ramp_indices(m::Model, unit, node, direction, t)

An iterator that concatenates `unit_flow_indices` and `units_on_indices` for the given inputs.
"""
function _constraint_unit_flow_capacity_w_ramp_indices(m::Model, unit, node, direction, t_before, t_after)
    Iterators.flatten((
        unit_flow_indices(m; unit=unit, node=node, direction=direction, t=t_before),
        units_on_indices(m; unit=unit, t=t_in_t(m; t_long=t_before)),
        units_on_indices(m; unit=unit, t=t_in_t(m; t_long=t_after)),
    ))
end
