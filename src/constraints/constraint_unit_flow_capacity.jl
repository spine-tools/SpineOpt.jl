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
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.

Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on, units_shut_down, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_flow_capacity] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t_flow, case=case, part=part) => @constraint(
            m,
            expr_sum(
                unit_flow[u, n, d, s, t_flow] * duration(t_flow) 
                for (u, n, d, s, t_flow) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t_flow)
                ) 
                if !is_reserve_node(node=n) || (
                    is_reserve_node(node=n) && upward_reserve(node=n) && !is_non_spinning(node=n)
                );
                init=0,
            )
            <=
            + expr_sum(
                + _flow_upper_bound(u, ng, d, s, t0, t_flow)
                * units_on[u, s, t_on]
                * min(duration(t_on), duration(t_flow))
                - _second_rhs_coeff(u, ng, d, s, t0, t_flow, t_on, case, part)
                * (
                    + expr_sum(
                        units_shut_down[u, s, t_on_after] * min(duration(t_on_after), duration(t_flow))
                        for (u, s, t_on_after) in units_on_indices(
                            m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t_on)
                        );
                        init=0
                    )                
                    + expr_sum(
                        nonspin_units_shut_down[u, n, s, t_ns_sd] * min(duration(t_ns_sd), duration(t_flow))
                        for (u, n, s, t_ns_sd) in nonspin_units_shut_down_indices(
                            m; unit=u, stochastic_scenario=s, t=t_on
                        );
                        init=0
                    )
                )
                - _third_rhs_coeff(u, ng, d, s, t0, t_flow, t_on, case, part)
                * units_started_up[u, s, t_on] * min(duration(t_on), duration(t_flow))
                for (u, s, t_on) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_flow))
            )
        )
        for (u, ng, d, s, t_flow, case, part) in constraint_unit_flow_capacity_indices(m)
    )
end

function _flow_upper_bound(u, ng, d, s, t0, t_flow)
    (
        + unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_flow)]
        * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_flow)]
    )
end

function _second_rhs_coeff(u, ng, d, s, t0, t_flow, t_on, case, part)
    if part == 1
        # (F - SD)
        + _flow_upper_bound(u, ng, d, s, t0, t_flow)
        - max_shutdown_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
    else
        # max(SU - SD, 0)
        max(
            (
                + max_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
                - max_shutdown_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
            ),
            0
        )
    end
end

function _third_rhs_coeff(u, ng, d, s, t0, t_flow, t_on, case, part)
    if case == 2 && part == 1
        # max(SD - SU, 0)
        max(
            (
                + max_shutdown_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
                - max_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
            ),
            0
        )
    else
        # (F - SU)
        + _flow_upper_bound(u, ng, d, s, t0, t_flow)
        - max_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_on)]
    end
end

function constraint_unit_flow_capacity_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=subpath, t=t_flow, case=case, part=part)
        for (u, ng, d) in indices(unit_capacity)
        for t_flow in time_slice(m; temporal_block=node__temporal_block(node=members(ng)))
        for path in active_stochastic_paths(
            m,
            [
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_flow);
                units_on_indices(
                    m; unit=u, t=[t_overlaps_t(m; t=t_flow); t_before_t(m; t_before=t_overlaps_t(m, t=t_flow))]
                )
            ]
        )
        for (subpath, case) in _subpaths(path, u, _analysis_time(m), t_flow)
        for part in 1:case  # Case 1 has only one part, case 2 has two parts
    )
end

"""
    _subpaths(path, u, t_flow)

Split the given stochastic path into subpaths of successive scenarios where the outcome
of min_up_time(...) > duration(t_flow) is the same.
"""
function _subpaths(path, u, t0, t_flow)
    isempty(path) && return ()
    all_subpaths = []
    current_subpath = []
    last_mut_gt_dur = nothing
    for s in path
        mut = min_up_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t_flow, _default=nothing)
        mut_gt_dur = mut === nothing || mut > duration(t_flow)
        if last_mut_gt_dur !== nothing && mut_gt_dur !== last_mut_gt_dur
            # Outcome change, store current subpath and start a new one
            case = last_mut_gt_dur ? 1 : 2  # Case 1 is min_up_time > dur, case 2 is the opposite
            push!(all_subpaths, (current_subpath, case))
            current_subpath = [s]
        else
            # No change, just extend the current subpath
            push!(current_subpath, s)
        end
        last_mut_gt_dur = mut_gt_dur
    end
    all_subpaths
end

"""
    constraint_unit_flow_capacity_indices_filtered(m::Model; filtering_options...)

Forms the stochastic indexing Array for the `:unit_flow_capacity` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and `units_on`
variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_flow_capacity_indices_filtered(
    m::Model; unit=anything, node=anything, direction=anything, stochastic_path=anything, t=anything
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_flow_capacity_indices(m))
end