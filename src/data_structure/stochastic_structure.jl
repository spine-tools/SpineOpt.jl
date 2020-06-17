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
    StochasticPathFinder

A callable type to retrieve intersections between valid stochastic paths
and 'active' scenarios.
"""
struct StochasticPathFinder
    full_stochastic_paths::Array{Array{Object,1},1}
end

"""
    active_stochastic_paths(active_scenarios::Union{Array{Object,1},Object})

The unique combinations of `active_scenarios` along valid stochastic paths.
"""
function (h::StochasticPathFinder)(active_scenarios::Union{Array{T,1},T}) where T
    # TODO: cache these
    unique(map(path -> intersect(path, active_scenarios), h.full_stochastic_paths))
end

"""
    _find_children(parent_scenario::Object)

The children of a `parent_scenario` as per the `parent_stochastic_scenario__child_stochastic_scenario` relationship.
"""
function _find_children(parent_scenario::Object)
    parent_stochastic_scenario__child_stochastic_scenario(stochastic_scenario1=parent_scenario)
end

"""
    _find_root_scenarios()

An `Array` of `stochastic_scenario` objects without parents.
"""
function _find_root_scenarios()
    all_scenarios = stochastic_scenario()
    children_scenarios = [child for (_parent, child) in parent_stochastic_scenario__child_stochastic_scenario()]
    setdiff(all_scenarios, children_scenarios)
end

"""
    _generate_active_stochastic_paths()

Find all unique paths through the `parent_stochastic_scenario__child_stochastic_scenario` tree
and generate the `active_stochastic_paths` callable.
"""
function _generate_active_stochastic_paths()
    paths = [[root] for root in _find_root_scenarios()]
    full_path_indices = []
    for (i, path) in enumerate(paths)
        children = _find_children(path[end])
        valid_children = setdiff(children, path)
        invalid_children = setdiff(children, valid_children)
        if !isempty(invalid_children)
            @warn """
            ignoring scenarios: $(join(invalid_children, ", ", " and ")), 
            as children of $(path[end]), since they're also its ancestors...
            """
        end
        isempty(valid_children) && push!(full_path_indices, i)
        append!(paths, [vcat(path, child) for child in valid_children])
    end
    # NOTE: `unique!` shouldn't be needed here since relationships are unique in the db.
    full_stochastic_paths = paths[full_path_indices]
    active_stochastic_paths = StochasticPathFinder(full_stochastic_paths)
    @eval begin
        active_stochastic_paths = $active_stochastic_paths
    end
end

"""
    _stochastic_DAG(stochastic_structure::Object, window_start::DateTime)

A `Dict` mapping `stochastic_scenario` objects to a `NamedTuple` of (start, end_, weight)
for the given `stochastic_structure` and `window_start`.
Aka DAG, that is, a *realized* stochastic structure with all the parameter values in place.
"""
function _stochastic_DAG(stochastic_structure::Object, window_start::DateTime)
    scenarios = _find_root_scenarios()
    scen_start = Dict(scen => window_start for scen in scenarios)
    scen_end = Dict()
    scen_weight = Dict(
        scen => weight_relative_to_parents(stochastic_structure=stochastic_structure, stochastic_scenario=scen)
        for scen in scenarios
    )
    window_very_end = end_(last(time_slice()))
    for scen in scenarios
        scenario_duration = stochastic_scenario_end(
            stochastic_structure=stochastic_structure, stochastic_scenario=scen, _strict=false
        )
        if scenario_duration === nothing
            scen_end[scen] = window_very_end
            continue
        end
        scenario_end = window_start + scenario_duration
        scen_end[scen] = scenario_end
        children = _find_children(scen)
        children_relative_weight = Dict(
            child => weight_relative_to_parents(
                stochastic_structure=stochastic_structure, stochastic_scenario=child, _strict=false
            )
            for child in children
        )
        valid_children = [child for (child, weight) in children_relative_weight if weight !== nothing]
        invalid_children = setdiff(children, valid_children)
        if !isempty(invalid_children)
            @warn """
            prunning scenarios: $(join(invalid_children, ", ", " and ")), from $(stochastic_structure)'s DAG, 
            since their value of `weight_relative_to_parents` is not specified
            """
        end
        for (child, child_relative_weight) in children_relative_weight
            scen_start[child] = haskey(scen_start, child) ? min(scen_start[child], scenario_end) : scenario_end
            scen_weight[child] = get(scen_weight, child, 0) + scen_weight[scen] * child_relative_weight
        end
        append!(scenarios, valid_children)
    end
    Dict(
        scen => (start=scen_start[scen], end_=scen_end[scen], weight=scen_weight[scen])
        for scen in scenarios
    )
end

"""
    _all_stochastic_DAGs(window_start::DateTime)

A `Dict` mapping `stochastic_structure` objects to DAGs.
"""
function _all_stochastic_DAGs(window_start::DateTime)
    Dict(structure => _stochastic_DAG(structure, window_start) for structure in stochastic_structure())
end

"""
    _stochastic_time_mapping(stochastic_DAG::Dict)

A `Dict` mapping `time_slice` objects to their set of active `stochastic_scenario` objects.
"""
function _stochastic_time_mapping(stochastic_DAG::Dict)
    # Active `time_slices`
    scenario_mapping = Dict(
        t => [scen for (scen, param_vals) in stochastic_DAG if param_vals.start <= start(t) < param_vals.end_]
        for t in time_slice()
    )
    # Historical `time_slices`
    roots = _find_root_scenarios()
    history_scenario_mapping = Dict(t => roots for t in sort(collect(values(t_history_t))))
    merge!(scenario_mapping, history_scenario_mapping)
end

"""
    _generate_stochastic_time_map(all_stochastic_DAGs)

Generate the `stochastic_time_map` for all defined `stochastic_structures`.
"""
function _generate_stochastic_time_map(all_stochastic_DAGs)
    stochastic_time_map = Dict(structure => _stochastic_time_mapping(DAG) for (structure, DAG) in all_stochastic_DAGs)
    @eval begin
        stochastic_time_map = $stochastic_time_map
    end
end

"""
    node_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `nodes`. Keyword arguments allow filtering.
"""
function node_stochastic_time_indices(;
        node=anything, stochastic_scenario=anything, temporal_block=anything, t=anything
    )
    unique(
        (node=n, stochastic_scenario=s, t=t1)
        for (n, structure) in node__stochastic_structure(node=node, _compact=false)
        for (n, tb) in node__temporal_block(node=n, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(temporal_block=tb, t=t)
        for s in intersect(stochastic_time_map[structure][t1], stochastic_scenario)
    )
end

"""
    unit_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `units`. Keyword arguments allow filtering.
"""
function unit_stochastic_time_indices(;
        unit=anything, stochastic_scenario=anything, temporal_block=anything, t=anything
    )
    unique(
        (unit=u, stochastic_scenario=s, t=t1)
        for (u, n) in units_on_resolution(unit=unit, _compact=false)
        for (n, s, t1) in node_stochastic_time_indices(
            node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

"""
    unit_investment_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `units_invested`. Keyword arguments allow filtering.
"""
function unit_investment_stochastic_time_indices(;
        unit=anything, stochastic_scenario=anything, temporal_block=anything, t=anything
    )
    unique(
        (unit=u, stochastic_scenario=s, t=t1)
        for (u, structure) in unit__investment_stochastic_structure(unit=unit, _compact=false)
        for (u, tb) in unit__investment_temporal_block(unit=unit, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(temporal_block=tb, t=t)
        for s in intersect(stochastic_time_map[structure][t1], stochastic_scenario)
    )
end


"""
    _generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)

Generate the `node_stochastic_scenario_weight` parameter for easier access to the scenario weights.
"""
function _generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)
    node_stochastic_scenario_weight_values = Dict(
        (node, scen) => Dict(:node_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (node, structure) in node__stochastic_structure()
        for (scen, param_vals) in all_stochastic_DAGs[structure]
    )
    node__stochastic_scenario = RelationshipClass(
        :node__stochastic_scenario,
        [:node, :stochastic_scenario],
        [(node=n, stochastic_scenario=scen) for (n, scen) in keys(node_stochastic_scenario_weight_values)],
        node_stochastic_scenario_weight_values
    )
    node_stochastic_scenario_weight = Parameter(:node_stochastic_scenario_weight, [node__stochastic_scenario])
    @eval begin
        node__stochastic_scenario = $node__stochastic_scenario
        node_stochastic_scenario_weight = $node_stochastic_scenario_weight
    end
end

"""
    unit_stochastic_scenario_weight(;unit, stochastic_scenario)

The value of `node_stochastic_scenario_weight` for the `node` associated to `unit`
as per the `units_on_resolution` relationship.
"""
function unit_stochastic_scenario_weight(;unit::Object, stochastic_scenario::Object)
    node_stochastic_scenario_weight(
        node=first(units_on_resolution(unit=unit)), stochastic_scenario=stochastic_scenario
    )
end

"""
    generate_stochastic_structure()

Preprocesses SpineOpt input data to form the required stochastic structure.

Runs a number of functions processing different aspects of the stochastics in sequence.
"""
function generate_stochastic_structure()
    all_stochastic_DAGs = _all_stochastic_DAGs(start(current_window))
    _generate_stochastic_time_map(all_stochastic_DAGs)
    _generate_node_stochastic_scenario_weight(all_stochastic_DAGs)
    _generate_active_stochastic_paths()
end