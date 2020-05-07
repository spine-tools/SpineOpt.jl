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
    find_children(stochastic_scenario::Object)

Finds and returns all the children of a `stochastic_scenario` defined by the 
`parent_stocahstic_scenario__child_stochastic_scenario` relationship.
"""
function find_children(stochastic_scenario::Object)
    parent_and_children = filter(
        x->x.stochastic_scenario1==stochastic_scenario,
        parent_stochastic_scenario__child_stochastic_scenario()
    )
    return [x.stochastic_scenario2 for x in parent_and_children]
end


"""
    find_root_scenarios()

Finds and returns all the `stochastic_scenarios` without parents.
"""
function find_root_scenarios()
    stochastic_tree = parent_stochastic_scenario__child_stochastic_scenario()
    parents = stochastic_scenario()
    children = [x.stochastic_scenario2 for x in stochastic_tree]
    return setdiff(parents, children)
end


"""
    find_full_stochastic_paths()

Finds all the unique paths through the `parent_stochastic_scenario__child_stochastic_scenario` tree.
"""
function find_full_stochastic_paths()
    root_scenarios = find_root_scenarios()
    all_paths = [[scen] for scen in root_scenarios]
    full_paths = Array{Array{Object,1},1}()
    for path in all_paths
        children = find_children(path[end])
        if isempty(children)
            push!(full_paths, path)
        else
            for child in children
                push!(all_paths, vcat(path, child))
            end
        end
    end
    return unique!(full_paths)
end


"""
    active_stochastic_paths(full_stochastic_paths::Array{Array{Object,1},1}, active_scenarios::Union{Array{Object,1},Object})

Finds all the unique combinations of active `stochastic_scenarios` along valid stochastic paths.
"""
function active_stochastic_paths(full_stochastic_paths::Array{Array{Object,1},1}, active_scenarios::Union{Array{Object,1},Object})
    unique(map(path -> intersect(path, active_scenarios), full_stochastic_paths))
end


"""
    generate_stochastic_tree(stochastic_structure, window_start)

Generates the stochastic tree of a `stochastic_structure` relative to a desired `window_start`
based on the `stochastic_scenario_end` parameters in the `stochastic_structure__stochastic_scenario` relationship.
"""
function generate_stochastic_tree(stochastic_structure::Object, window_start::DateTime)
    scenarios = find_root_scenarios()
    scen_start = Dict()
    scen_end = Dict()
    scen_weight = Dict()
    for root_scenario in scenarios
        scen_start[root_scenario] = window_start
        scen_weight[root_scenario] = weight_relative_to_parent(stochastic_structure=stochastic_structure, stochastic_scenario=root_scenario)
    end
    for scen in scenarios
        if (stochastic_structure=stochastic_structure, stochastic_scenario=scen) in indices(stochastic_scenario_end)
            scen_end[scen] = window_start + stochastic_scenario_end(stochastic_structure=stochastic_structure, stochastic_scenario=scen)
            children = find_children(scen)
            for child in children
                scen_start[child] = min(get(scen_start, child, scen_end[scen]), scen_end[scen])
                child_weight = weight_relative_to_parent(stochastic_structure=stochastic_structure, stochastic_scenario=child) * scen_weight[scen]
                scen_weight[child] = get(scen_weight, child, 0) + child_weight
            end
            append!(scenarios, children)
        end
    end
    stochastic_tree = Dict()
    for scen in scenarios
        stochastic_tree[scen] = (
            start = scen_start[scen],
            end_ = get(scen_end, scen, last(time_slice()).end_.x),
            weight = scen_weight[scen]
        )
    end
    return stochastic_tree
end


"""
    generate_all_stochastic_trees(window_start::DateTime)

Generates the stochastic trees of every `stochastic_structure`.
"""
function generate_all_stochastic_trees(window_start::DateTime)
    stochastic_trees = Dict()
    for structure in stochastic_structure()
        stochastic_trees[structure] = generate_stochastic_tree(structure, window_start)
    end
    return stochastic_trees
end


"""
    node_stochastic_time_indices(node::Object, stochastic_tree::Dict)

Function to generate the `(node, stochastic_scenario, time_slice)` indices
for a `node` based on a stochastic tree.
"""
function node_stochastic_time_indices(node::Object, stochastic_tree::Dict)
    node__stochastic_scenario__time_slice = []
    for temporal_block in node__temporal_block(node=node)
        for t in time_slice.block_time_slices[temporal_block]
            scenarios = keys(filter(tree->tree[2].start <= t.start.x < tree[2].end_, stochastic_tree))
            for scen in scenarios
                push!(
                    node__stochastic_scenario__time_slice,
                    (node=node, stochastic_scenario=scen, t=t)
                )
            end
        end
    end
    return node__stochastic_scenario__time_slice
end


"""
    node_stochastic_time_indices_history(node::Object)

Function to generate the `(node, stochastic_scenario, time_slice)` indices
for a `node` for the historical time steps, based on root `stochastic_scenarios`.
"""
function node_stochastic_time_indices_history(node::Object)
    node__stochastic_scenario__time_slice_history = [
        (node=node, stochastic_scenario=scen, t=t)
        for scen in find_root_scenarios()
        for t in sort(collect(values(t_history_t)))
    ]
    return node__stochastic_scenario__time_slice_history
end


"""
    generate_node_stochastic_time_indices(window_start::DateTime)

Generates the `node_stochastic_time_indices_rc` and `all_node_stochastic_time_indices_rc`
RelationshipClasses to store the stochastic time indices for all `nodes`,
based on all of the stochastic trees of all defined `stochastic_structures`.

`node_stochastic_time_indices_rc` stores the current active stochastic time steps, while
`all_node_stochastic_time_indices_rc` also includes the historical time steps.
"""
function generate_node_stochastic_time_indices(all_stochastic_trees::Dict)
    node__stochastic_scenario__t = []
    node__stochastic_scenario__t_history = []
    for (node, structure) in node__stochastic_structure()
        if length(node__stochastic_structure(node=node)) > 1
            error("Node `$(node)` cannot have more than one `stochastic_structure`!")
        end
        node_stochastic_time = node_stochastic_time_indices(node, all_stochastic_trees[structure])
        append!(node__stochastic_scenario__t, node_stochastic_time)
        node_stochastic_time_history = node_stochastic_time_indices_history(node)
        append!(node__stochastic_scenario__t_history, node_stochastic_time_history)
    end
    unique!(node__stochastic_scenario__t)
    unique!(node__stochastic_scenario__t_history)
    node_stochastic_time_indices_rc = RelationshipClass(
        :node_stochastic_time_indices_rc, [:node, :stochastic_scenario, :t], node__stochastic_scenario__t
    )
    all_node_stochastic_time_indices_rc = RelationshipClass(
        :all_node_stochastic_time_indices_rc,
        [:node, :stochastic_scenario, :t],
        unique(vcat(node__stochastic_scenario__t_history, node__stochastic_scenario__t))
    )
    @eval begin
        node_stochastic_time_indices_rc = $node_stochastic_time_indices_rc
        all_node_stochastic_time_indices_rc = $all_node_stochastic_time_indices_rc
    end
end


"""
    node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to the *current* nodal stochastic time indices.
The keyword arguments act as filters for each dimension.
"""
function node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, t=anything)
    node_stochastic_time_indices_rc(node=node, stochastic_scenario=stochastic_scenario, t=t, _compact=false)    
end


"""
    all_node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to the current and *historical* nodal stochastic time indices.
The keyword arguments act as filters for each dimension.
"""
function all_node_stochastic_time_indices(;node=anything, stochastic_scenario=anything, t=anything)
    all_node_stochastic_time_indices_rc(node=node, stochastic_scenario=stochastic_scenario, t=t, _compact=false)    
end


"""
    generate_unit__structure_node()

Generates a new RelationshipClass `unit__structure_node` that maps each `unit` to a `node` that defines
the stochastic and temporal structure of the `units_on` and related variables/parameters.
"""
function generate_unit__structure_node() # TODO: This function could be in preprocess data structure?
    units = unit()
    imported_temporal_structures = collect(indices(import_temporal_structure))
    filter!(
        inds -> import_temporal_structure(unit=inds.unit, node=inds.node, direction=inds.direction) == :value_true,
        imported_temporal_structures
    )
    unit__structure_node = []
    for u in units
        temporal_structure = filter(und -> und.unit == u, imported_temporal_structures)
        if length(temporal_structure) != 1
            error("Unit `$(u)` must have exactly one `import_temporal_structure` set to `value_true`!")
        end
        push!(
            unit__structure_node,
            (unit=u, node=first(temporal_structure).node)
        )
    end
    unique!(unit__structure_node)
    unit__structure_node_rc = RelationshipClass(
        :unit__structure_node_rc, [:unit, :node], unit__structure_node
    )
    @eval begin
        unit__structure_node_rc = $unit__structure_node_rc
    end
end


"""
    unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to the *current* unit stochastic time indices.
The keyword arguments act as filters for each dimension.
"""
function unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, t=anything)
    [
        (unit=u, stochastic_scenario=s, t=t)
        for (u, n) in unit__structure_node_rc(unit=unit, _compact=false)
        for (n, s, t) in node_stochastic_time_indices(
            node=n,
            stochastic_scenario=stochastic_scenario,
            t=t
        )
    ]
end


"""
    all_unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, t=anything)

A list of `NamedTuple`s corresponding to the current and *historical* unit stochastic time indices.
The keyword arguments act as filters for each dimension.
"""
function all_unit_stochastic_time_indices(;unit=anything, stochastic_scenario=anything, t=anything)
    [
        (unit=u, stochastic_scenario=s, t=t)
        for (u, n) in unit__structure_node_rc(unit=unit, _compact=false)
        for (n, s, t) in all_node_stochastic_time_indices(
            node=n,
            stochastic_scenario=stochastic_scenario,
            t=t
        )
    ]
end


"""
    generate_node_stochastic_scenario_weight(all_stochastic_trees::Dict)

Generates the `node_stochastic_scenario_weight` parameter for easier access to the scenario weights.
"""
function generate_node_stochastic_scenario_weight(all_stochastic_trees::Dict)
    node_scenario = []
    parameter_vals = Dict{Tuple{Vararg{Object}},Dict{Symbol,AbstractCallable}}()
    for (node, structure) in node__stochastic_structure()
        if length(node__stochastic_structure(node=node)) > 1
            error("Node `$(node)` cannot have more than one `stochastic_structure`!")
        end
        scenarios = keys(all_stochastic_trees[structure])
        for scen in scenarios
            push!(node_scenario, (node=node, stochastic_scenario=scen))
            parameter_vals[(node, scen)] = Dict{Symbol,AbstractCallable}()
            val = all_stochastic_trees[structure][scen].weight
            if isnothing(val)
                error("`stochastic_structure` `$(structure)` lacks a `weight_relative_to_parent` for `stochastic_scenario` `$(scen)`!")
            end
            push!(
                parameter_vals[(node, scen)],
                :node_stochastic_scenario_weight => SpineInterface.ScalarCallable(val)
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
        for (u, n) in unit__structure_node_rc(unit=unit, _compact=false)
        for (n, s) in node__stochastic_scenario(node=n, _compact=false)
    ]
end


"""
    unit_stochastic_scenario_weight(;unit=anything, stochastic_scenario=anything)

A function to access the `node_stochastic_scenario_weight` parameter from the `import_temporal_structure`
`node` defined for the `unit`.
"""
function unit_stochastic_scenario_weight(;unit=nothing, stochastic_scenario=nothing)
    if isnothing(unit) || isnothing(stochastic_scenario)
        error("Both a `unit` and `stochastic_scenario` are required to access `unit_stochastic_scenario_weight`!")
    else
        for (u, n) in unit__structure_node_rc(unit=unit, _compact=false)
            return node_stochastic_scenario_weight(node=n, stochastic_scenario=stochastic_scenario)
        end
    end
end