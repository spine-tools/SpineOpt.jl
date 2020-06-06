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

struct StochasticPathFinder
    full_stochastic_paths::Array{Array{Object,1},1}
end

"""
    active_stochastic_paths(active_scenarios::Union{Array{Object,1},Object})

The unique combinations of `active_scenarios` along valid stochastic paths.
"""
function (h::StochasticPathFinder)(active_scenarios::Union{Array{Object,1},Object})
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
        isempty(children) && push!(full_path_indices, i)
        append!(paths, [vcat(path, child) for child in children])
    end
    # TODO: `unique!` shouldn't be needed here since relationships are unique in the db.
    # But we need a check to make sure the stochastic structure is a DAG (no loops)
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
    for scen in scenarios
        scenario_end = stochastic_scenario_end(
            stochastic_structure=stochastic_structure, stochastic_scenario=scen, _strict=false
        )
        if scenario_end !== nothing
            scenario_end += window_start
            scen_end[scen] = scenario_end
            children = _find_children(scen)
            for child in children
                scen_start[child] = min(get(scen_start, child, scenario_end), scenario_end)
                child_weight = scen_weight[scen] * weight_relative_to_parents(
                    stochastic_structure=stochastic_structure, stochastic_scenario=child
                )
                scen_weight[child] = get(scen_weight, child, 0) + child_weight
            end
            append!(scenarios, children)
        end
    end
    last_time = end_(last(time_slice()))
    Dict(
        scen => (start=scen_start[scen], end_=get(scen_end, scen, last_time), weight=scen_weight[scen])
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
        t => [scen for (scen, value) in stochastic_DAG if value.start <= start(t) < value.end_]
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
    node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, t=anything)

Convenience function for accessing the full stochastic time indexing of `nodes`. Keyword arguments allow filtering.
"""
function node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, temporal_block=anything, t=anything)
    unique( # TODO: Write a check for multiple structures
        (node=n, stochastic_scenario=s, t=t1)
        for (n, structure) in node__stochastic_structure(node=node, _compact=false)
        for (n, tb) in node__temporal_block(node=n, temporal_block=temporal_block, _compact=false)
        for t1 in time_slice(temporal_block=tb, t=t)
        for s in intersect(stochastic_time_map[structure][t1], stochastic_scenario)
    )
end


"""
    unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, t=anything)

Convenience function for accessing the full stochastic time indexing of `units`. Keyword arguments allow filtering.
"""
function unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, temporal_block=anything, t=anything)
    unique(
        (unit=u, stochastic_scenario=s, t=t1)
        for (u, n) in units_on_resolution(unit=unit, _compact=false) # TODO: Write a check for multiple relationships
        for (n, s, t1) in node_stochastic_time_indices(
            node=n, stochastic_scenario=stochastic_scenario, temporal_block=temporal_block, t=t
        )
    )
end

"""
    _generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)

Generate the `node_stochastic_scenario_weight` parameter for easier access to the scenario weights.
"""
function _generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)
    node_scenario = []
    parameter_vals = Dict{Tuple{Vararg{Object}},Dict{Symbol,AbstractParameterValue}}()
    for (node, structure) in node__stochastic_structure()
        scenarios = keys(all_stochastic_DAGs[structure])
        for scen in scenarios
            push!(node_scenario, (node=node, stochastic_scenario=scen))
            parameter_vals[(node, scen)] = Dict{Symbol,AbstractParameterValue}()
            val = all_stochastic_DAGs[structure][scen].weight
            if isnothing(val)
                error("`stochastic_structure` `$(structure)` lacks a `weight_relative_to_parents` for `stochastic_scenario` `$(scen)`!")
            end
            push!(
                parameter_vals[(node, scen)],
                :node_stochastic_scenario_weight => SpineInterface.ScalarParameterValue(val)
            )
        end
    end
    node__stochastic_scenario = RelationshipClass(
        :node__stochastic_scenario, [:node, :stochastic_scenario], node_scenario, parameter_vals
    )
    node_stochastic_scenario_weight = Parameter(:node_stochastic_scenario_weight, [node__stochastic_scenario])
    @eval begin
        node__stochastic_scenario = $node__stochastic_scenario
        node_stochastic_scenario_weight = $node_stochastic_scenario_weight
    end
end


"""
    unit__stochastic_scenario(;unit=anything, stochastic_scenario=anything, _compact=false)

A list of `NamedTuple`s corresponding to the `unit`s and their `stochastic_scenario`s.
The keyword arguments act as filters for each dimension.
"""
function unit__stochastic_scenario(;unit=anything, stochastic_scenario=anything)
    [
        (unit=u, stochastic_scenario=s)
        for (u, n) in units_on_resolution(unit=unit, _compact=false)
        for (n, s) in node__stochastic_scenario(node=n, _compact=false)
    ]
end


"""
    unit_stochastic_scenario_weight(;unit=anything, stochastic_scenario=anything)

A function to access the `node_stochastic_scenario_weight` parameter from the `node` defined for the `unit`.
"""
function unit_stochastic_scenario_weight(;unit=nothing, stochastic_scenario=nothing)
    if isnothing(unit) || isnothing(stochastic_scenario)
        error("Both a `unit` and `stochastic_scenario` are required to access `unit_stochastic_scenario_weight`!")
    else
        for (u, n) in units_on_resolution(unit=unit, _compact=false)
            return node_stochastic_scenario_weight(node=n, stochastic_scenario=stochastic_scenario)
        end
    end
end

function generate_stochastic_structure()
    all_stochastic_DAGs = _all_stochastic_DAGs(start(current_window))
    _generate_stochastic_time_map(all_stochastic_DAGs)
    _generate_node_stochastic_scenario_weight(all_stochastic_DAGs)
    _generate_active_stochastic_paths()
end