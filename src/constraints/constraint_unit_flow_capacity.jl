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
    @fetch unit_flow, units_on, units_started_up, units_shut_down, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_flow_capacity] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t_on, case=case, part=part) => @constraint(
            m,
            expr_sum(
                unit_flow[u, n, d, s, t_flow] * duration(t_on) / duration(t_flow)
                for (u, n, d, s, t_flow) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_on)
                ) 
                if !is_reserve_node(node=n) || (
                    is_reserve_node(node=n) && upward_reserve(node=n) && !is_non_spinning(node=n)
                );
                init=0,
            )
            <=
            + expr_sum(
                _unit_flow_capacity(u, ng, d, s, t0, t_on) * units_on[u, s, t_on]
                for (u, s, t_on) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_on);
                init=0
            )
            - (
                + expr_sum(
                    + _shutdown_margin(u, ng, d, s, t0, t_on, case, part)
                    * _unit_flow_capacity(u, ng, d, s, t0, t_on)
                    * units_shut_down[u, s, t_on_after]
                    for (u, s, t_on_after) in units_on_indices(
                        m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t_on)
                    );
                    init=0
                )                
                + expr_sum(
                    + _shutdown_margin(u, ng, d, s, t0, t_on, case, part)
                    * _unit_flow_capacity(u, ng, d, s, t0, t_on)
                    * nonspin_units_shut_down[u, n, s, t_ns_sd]
                    for (u, n, s, t_ns_sd) in nonspin_units_shut_down_indices(
                        m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_on)
                    );
                    init=0
                )
            )
            - expr_sum(
                + _startup_margin(u, ng, d, s, t0, t_on, case, part)
                * _unit_flow_capacity(u, ng, d, s, t0, t_on)
                * units_started_up[u, s, t_on]
                for (u, s, t_on_after) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_on);
                init=0
            )
        )
        for (u, ng, d, s, t_on, case, part) in constraint_unit_flow_capacity_indices(m)
    )
end

function _shutdown_margin(u, ng, d, s, t0, t_on, case, part)
    if part.name == :one
        # (F - SD)
        1 - _shut_down_limit(u, ng, d, s, t0, t_on)
    else
        # max(SU - SD, 0)
        max(_start_up_limit(u, ng, d, s, t0, t_on) - _shut_down_limit(u, ng, d, s, t0, t_on), 0)
    end
end

function _startup_margin(u, ng, d, s, t0, t_on, case, part)
    if case.name == :min_up_time_le_time_step && part.name == :one
        # max(SD - SU, 0)
        max(_shut_down_limit(u, ng, d, s, t0, t_on) - _start_up_limit(u, ng, d, s, t0, t_on), 0)
    else
        # (F - SU)
        1 - _start_up_limit(u, ng, d, s, t0, t_on)
    end
end

function constraint_unit_flow_capacity_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=subpath, t=t_on, case=case, part=part)
        for (u, ng, d) in indices(unit_capacity)
        for t_on in t_highest_resolution(time_slice(m; temporal_block=units_on__temporal_block(unit=u)))
        for path in active_stochastic_paths(
            m,
            [
                units_on_indices(m; unit=u, t=[t_on; t_before_t(m; t_before=t_on)]);
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_overlaps_t(m; t=t_on));
                nonspin_units_shut_down_indices(m; unit=u, t=t_overlaps_t(m; t=t_on))
            ]
        )
        for (subpath, parts_by_case) in _unit_capacity_constraint_subpaths(path, u, _analysis_time(m), t_on)
        for (case, parts) in parts_by_case
        for part in parts
    )
end

"""
    _unit_capacity_constraint_subpaths(path, u, t_on)

Split the given stochastic path into subpaths of successive scenarios where the outcome
of min_up_time(...) > duration(t_on) is the same.
"""
function _unit_capacity_constraint_subpaths(path, u, t0, t_on)
    isempty(path) && return ()
    all_subpaths = []
    current_subpath = []
    last_mut_gt_dur = nothing
    t_flow_duration = end_(t_on) - start(t_on)
    for s in path
        mut = min_up_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t_on, _default=nothing)
        mut_gt_dur = mut === nothing || mut > t_flow_duration
        if last_mut_gt_dur !== nothing && mut_gt_dur !== last_mut_gt_dur
            # Outcome change, store current subpath and start a new one
            push!(all_subpaths, (current_subpath, _parts_by_case(last_mut_gt_dur)))
            current_subpath = [s]
        else
            # No change, just extend the current subpath
            push!(current_subpath, s)
        end
        last_mut_gt_dur = mut_gt_dur
    end
    push!(all_subpaths, (current_subpath, _parts_by_case(last_mut_gt_dur)))
    all_subpaths
end

function _parts_by_case(last_mut_gt_dur)
    if last_mut_gt_dur
        Dict(Object(:min_up_time_gt_time_step, :case) => (Object(:one, :part),)) 
    else
        Dict(Object(:min_up_time_le_time_step, :case) => (Object(:one, :part), Object(:two, :part))) 
    end
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
