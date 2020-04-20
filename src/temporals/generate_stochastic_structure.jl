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
    parents = [x.stochastic_scenario1 for x in stochastic_tree]
    children = [x.stochastic_scenario2 for x in stochastic_tree]
    return setdiff(parents, children)
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
            timeslice = TimeSlice(scen_start[scen], get(scen_end, scen, last(time_slice()).end_.x)),
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
            scenarios = keys(filter(tree->tree[2].timeslice.start.x <= t.start.x < tree[2].timeslice.end_.x, stochastic_tree))
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
    generate_node_stochastic_time_indices(window_start::DateTime)

Function to generate the `(node__stochastic_scenario__time_slice)` indices for all `nodes`.
"""
function generate_node_stochastic_time_indices(window_start::DateTime)
    all_stochastic_trees = generate_all_stochastic_trees(window_start)
    node__stochastic_scenario__time_slice = []
    for (node, structure) in node__stochastic_structure()
        if length(node__stochastic_structure(node=node)) > 1
            @error("Node `$(node)` cannot have more than one `stochastic_structure`!")
        end
        node_stochastic_time = node_stochastic_time_indices(node, all_stochastic_trees[structure])
        append!(node__stochastic_scenario__time_slice, node_stochastic_time)
    end
    return node__stochastic_scenario__time_slice
end