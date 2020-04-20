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

Finds and returns all the children of a `stochastic_scenario` in the stochastic tree
defined by the `parent_stocahstic_scenario__child_stochastic_scenario` relationship.
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

Finds and returns all the `stochastic_scenarios` that don't have parents
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
                if isnothing(get(scen_start, child, nothing))
                    scen_start[child] = scen_end[scen]
                else
                    scen_start[child] = min(scen_start[child], scen_end[scen])
                end
                child_weight = weight_relative_to_parent(stochastic_structure=stochastic_structure, stochastic_scenario=child) * scen_weight[scen]
                if isnothing(get(scen_weight, child, nothing))
                    scen_weight[child] = child_weight
                else
                    scen_weight[child] += child_weight
                end
            end
            append!(scenarios, children)
        end
    end
    stochastic_tree = Dict()
    for scen in scenarios
        stochastic_tree[(stochastic_structure=stochastic_structure, stochastic_scenario=scen)] = (
            timeslice = TimeSlice(scen_start[scen], get(scen_end, scen, last(time_slice()).end_.x)),
            weight = scen_weight[scen]
        )
    end
    return stochastic_tree
end


"""
    generate_stochastic_forest(window_start::)

Generates the stochastic trees of every `stochastic_structure`.
"""
function generate_stochastic_forest(window_start::DateTime)
    stochastic_forest = Dict()
    for structure in stochastic_structure()
        merge!(
            stochastic_forest,
            generate_stochastic_tree(structure, window_start)
        )
    end
    return stochastic_forest
end

#=
"""
    generate_node_stochastic_time_indices()

Function to access 
"""
function generate_node_stochastic_time_indices(window_start::TimeSlice)
    scenarios = find_root_scenarios()
    scenario_ = Dict{Tuple{Object,Object},TimeSlice}()
    scenario_end = Dict{Tuple{Object,Object},TimeSlice}()
    for scen in scenarios

    end
end
=#