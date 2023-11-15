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

@doc raw""""
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.

    #description
    In a multi-commodity setting, there can be different commodities entering/leaving a certain
    technology/unit. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
    emissions, or other commodities (e.g., water, steel). The [unit\_capacity](@ref) must be specified
    for at least one [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship,
    in order to trigger a constraint on the maximum commodity flows to this location in each time step.
    When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products).

    Note 1: the conversion factor [unit\_conv\_cap\_to\_flow](@ref) has a default value of `1`, but can be adjusted
    in case the unit of measurement for the capacity is different to the unit flows unit of measurement.

    Note 2: The below formulation is valid for time-slices whose duration is greater than the minimum up time of the
    unit.
    This ensures that the unit is not online for exactly one time-slice, which might result in an infeasibility
    with the below formulation.
    For time-slices whose duration is lower or equal than the minimum up time of the unit there is a similar
    formulation, but the details are omitted for brevity.

    Note 3: The below formulation is valid for flows going from a unit to a node (i.e., output flows).
    For flows going from a node to a unit (i.e., input flows) the second term on the LHS
    is replaced by the sumation over nodes with *downward* reserve requirements (instead of *upward*).
    #end description

    #formulation
    ```math
    \begin{aligned}
    & \sum_{
        \substack{
            (u,n,d,s,t_{flow}) \in unit\_flow\_indices: \\
            n \in ng, \, s \in s_{path}, \, t_{flow} \in t\_overlaps\_t(t) \\
            !p_{is\_reserve}(n)
        }
    } v_{unit\_flow}(u,n,d,s,t_{flow}) \cdot \Delta t / \Delta t_{flow} \\
    & + \sum_{
        \substack{
            (u,n,d,s,t_{flow}) \in unit\_flow\_indices: \\
            n \in ng, \, s \in s_{path}, \, t_{flow} \in t\_overlaps\_t(t) \\
            p_{is\_reserve}(n), \, p_{upward\_reserve}(n) \\
            !p_{is\_non\_spinning}(n)
        }
    } v_{unit\_flow}(u,n,d,s,t_{flow}) \cdot \Delta t / \Delta t_{flow} \\
    & <= p_{unit\_capacity}(u,ng,d,s,t) \\
    & \cdot p_{unit\_availability\_factor}(u,s,t) \\
    & \cdot p_{unit\_conv\_cap\_to\_flow}(u,ng,d,s,t) \\
    & \cdot ( \\
    & \sum_{
        \substack{
            (u,s,t) \in units\_on\_indices:\\
            s \in s_{path}
        }
    } v_{units\_on}(u,s,t) \\
    & + (1 - p_{shut\_down\_limit}(u,ng,d,s,t)) \cdot \sum_{
        \substack{
            (u,s,t_{after}) \in units\_on\_indices:\\
            s \in s_{path}, \, t_{after} \in t\_before\_t(t\_before=t)
        }
    } v_{units\_shut\_down}(u,s,t_{after}) \\
    & - (1 - p_{start\_up\_limit}(u,ng,d,s,t)) \cdot \sum_{
        \substack{
            (u,s,t) \in units\_on\_indices:\\
            s \in s_{path}
        }
    } v_{units\_started\_up}(u,s,t) \\
    & ) \\
    & \forall (u,ng,d) \in ind(p_{unit\_capacity}), \\
    & \forall t \in t\_highest\_resolution(u), \\
    & \forall s_{path} \in stochastic\_paths(t)
    \end{aligned}
    ```
    #end formulation
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on, units_started_up, units_shut_down, nonspin_units_shut_down = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_flow_capacity] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t, case=case, part=part) => @constraint(
            m,
            expr_sum(
                unit_flow[u, n, d, s, t_over] * overlap_duration(t_over, t)
                for (u, n, d, s, t_over) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t)
                ) 
                if !is_reserve_node(node=n) || (
                    is_reserve_node(node=n)
                    && _switch(d; to_node=upward_reserve, from_node=downward_reserve)(node=n)
                    && !is_non_spinning(node=n)
                );
                init=0,
            )
            <=
            + expr_sum(
                _unit_flow_capacity(u, ng, d, s, t0, t) * units_on[u, s, t_over] * overlap_duration(t_over, t)
                for (u, s, t_over) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0
            )
            - (
                + expr_sum(
                    + _shutdown_margin(u, ng, d, s, t0, t, case, part)
                    * _unit_flow_capacity(u, ng, d, s, t0, t)
                    * units_shut_down[u, s, t_after]
                    * duration(t_after)
                    for (u, s, t_after) in units_on_indices(
                        m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t)
                    );
                    init=0
                )                
                + expr_sum(
                    + _shutdown_margin(u, ng, d, s, t0, t, case, part)
                    * _unit_flow_capacity(u, ng, d, s, t0, t)
                    * nonspin_units_shut_down[u, n, s, t_over]
                     * overlap_duration(t_over, t)
                    for (u, n, s, t_over) in nonspin_units_shut_down_indices(
                        m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t)
                    );
                    init=0
                )
            )
            - expr_sum(
                + _startup_margin(u, ng, d, s, t0, t, case, part)
                * _unit_flow_capacity(u, ng, d, s, t0, t)
                * units_started_up[u, s, t_over]
                for (u, s, t_over) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0
            )
        )
        for (u, ng, d, s, t, case, part) in constraint_unit_flow_capacity_indices(m)
    )
end

function _shutdown_margin(u, ng, d, s, t0, t, case, part)
    if part.name == :one
        # (F - SD)
        1 - _shut_down_limit(u, ng, d, s, t0, t)
    else
        # max(SU - SD, 0)
        max(_start_up_limit(u, ng, d, s, t0, t) - _shut_down_limit(u, ng, d, s, t0, t), 0)
    end
end

function _startup_margin(u, ng, d, s, t0, t, case, part)
    if case.name == :min_up_time_le_time_step && part.name == :one
        # max(SD - SU, 0)
        max(_shut_down_limit(u, ng, d, s, t0, t) - _start_up_limit(u, ng, d, s, t0, t), 0)
    else
        # (F - SU)
        1 - _start_up_limit(u, ng, d, s, t0, t)
    end
end

function constraint_unit_flow_capacity_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=subpath, t=t, case=case, part=part)
        for (u, ng, d) in indices(unit_capacity)
        for t in t_highest_resolution(
            Iterators.flatten(
                ((t for (u, t) in unit_time_indices(m; unit=u)), (t for (ng, t) in node_time_indices(m; node=ng)))
            )
        )
        for path in active_stochastic_paths(
            m,
            [
                units_on_indices(m; unit=u, t=[t_overlaps_t(m; t=t); t_before_t(m; t_before=t)]);
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_overlaps_t(m; t=t));
                nonspin_units_shut_down_indices(m; unit=u, t=t_overlaps_t(m; t=t))
            ]
        )
        for (subpath, parts_by_case) in _unit_capacity_constraint_subpaths(path, u, _analysis_time(m), t)
        for (case, parts) in parts_by_case
        for part in parts
    )
end

"""
    _unit_capacity_constraint_subpaths(path, u, t)

Split the given stochastic path into subpaths of successive scenarios where the outcome
of min_up_time(...) > duration(t) is the same.
"""
function _unit_capacity_constraint_subpaths(path, u, t0, t)
    isempty(path) && return ()
    all_subpaths = []
    current_subpath = []
    last_mut_gt_dur = nothing
    t_flow_duration = end_(t) - start(t)
    for s in path
        mut = min_up_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t, _default=nothing)
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
