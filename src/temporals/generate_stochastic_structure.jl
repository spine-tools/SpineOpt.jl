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
    roots = stochastic_scenario()
    children = [x.stochastic_scenario2 for x in stochastic_tree]
    return setdiff(roots, children)
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
    active_stochastic_paths(
        full_stochastic_paths::Array{Array{Object,1},1},
        active_scenarios::Union{Array{Object,1},Object}
    )

Finds all the unique combinations of active `stochastic_scenarios` along valid stochastic paths.
"""
function active_stochastic_paths(
    full_stochastic_paths::Array{Array{Object,1},1},
    active_scenarios::Union{Array{Object,1},Object}
)
    unique(map(path -> intersect(path, active_scenarios), full_stochastic_paths))
end


"""
    generate_stochastic_DAG(stochastic_structure::Object, window_start::DateTime)

Generates the stochastic DAG of a `stochastic_structure` relative to a desired `window_start`
based on the `stochastic_scenario_end` parameters in the `stochastic_structure__stochastic_scenario` relationship.
"""
function generate_stochastic_DAG(stochastic_structure::Object, window_start::DateTime)
    scenarios = find_root_scenarios()
    scen_start = Dict()
    scen_end = Dict()
    scen_weight = Dict()
    for root_scenario in scenarios
        scen_start[root_scenario] = window_start
        scen_weight[root_scenario] = weight_relative_to_parents(
            stochastic_structure=stochastic_structure, stochastic_scenario=root_scenario
        )
    end
    for scen in scenarios
        if (stochastic_structure=stochastic_structure, stochastic_scenario=scen) in indices(stochastic_scenario_end)
            scen_end[scen] = window_start + stochastic_scenario_end(
                stochastic_structure=stochastic_structure, stochastic_scenario=scen
            )
            children = find_children(scen)
            for child in children
                scen_start[child] = min(get(scen_start, child, scen_end[scen]), scen_end[scen])
                child_weight = scen_weight[scen] * weight_relative_to_parents(
                    stochastic_structure=stochastic_structure, stochastic_scenario=child
                )
                scen_weight[child] = get(scen_weight, child, 0) + child_weight
            end
            append!(scenarios, children)
        end
    end
    stochastic_DAG = Dict()
    for scen in scenarios
        stochastic_DAG[scen] = (
            start = scen_start[scen],
            end_ = get(scen_end, scen, last(time_slice()).end_.x),
            weight = scen_weight[scen]
        )
    end
    return stochastic_DAG
end


"""
    generate_all_stochastic_DAG(window_start::DateTime)

Generates the stochastic DAGs of every `stochastic_structure`.
"""
function generate_all_stochastic_DAGs(window_start::DateTime)
    stochastic_DAGs = Dict()
    for structure in stochastic_structure()
        stochastic_DAGs[structure] = generate_stochastic_DAG(structure, window_start)
    end
    return stochastic_DAGs
end


"""
    stochastic_time_mapping(stochastic_DAG::Dict)

Maps `(stochastic_structure, time_slice)` to their set of active `stochastic_scenarios`.
"""
function stochastic_time_mapping(stochastic_DAG::Dict)
    active_scenario_map = Dict{TimeSlice, Array{Union{Int64,T} where T<:SpineInterface.AbstractObject,1}}()
    # Active `time_slices`
    for t in time_slice()
        active_scenario_map[t] = collect(
            keys(filter(DAG->DAG[2].start <= t.start.x < DAG[2].end_, stochastic_DAG))
        )
    end
    # Historical `time_slices`
    root = find_root_scenarios()
    for t in sort(collect(values(t_history_t)))
        active_scenario_map[t] = root
    end
    return active_scenario_map
end


"""
    generate_stochastic_time_map(all_stochastic_DAGs)

Generates the `stochastic_time_map` for all defined `stochastic_structures`.
"""
function generate_stochastic_time_map(all_stochastic_DAGs)
    stochastic_time_map = Dict{Object, Dict{TimeSlice, Array{Union{Int64,T} where T<:SpineInterface.AbstractObject,1}}}()
    for structure in stochastic_structure()
        stochastic_time_map[structure] = stochastic_time_mapping(all_stochastic_DAGs[structure])
    end
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
    generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)

Generates the `node_stochastic_scenario_weight` parameter for easier access to the scenario weights.
"""
function generate_node_stochastic_scenario_weight(all_stochastic_DAGs::Dict)
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