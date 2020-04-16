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
    reduced_tree = filter(
        x->x.stochastic_scenario1==stochastic_scenario,
        parent_stochastic_scenario__child_stochastic_scenario()
    )
    return [x.stochastic_scenario2 for x in reduced_tree]
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
    nodal_stochastic_tree(node, window_start)

Generates the stochastic tree of a `node` relative to a desired `window_start`
based on the `scenario_end` parameters in the `node__stochastic_scenario` relationship.
"""
function nodal_stochastic_tree(node, window_start)
    scenarios = find_root_scenarios()
    scen_start = Dict()
    scen_end = Dict()
    for root_scenario in scenarios
        scen_start[root_scenario] = window_start
    end
    for scen in scenarios
        if (node=node, stochastic_scenario=scen) in indices(scenario_end)
            scen_end[scen] = window_start + scenario_end(node=node, stochastic_scenario=scen)
            children = find_children(scen)
            for child in children
                if isnothing(get(scen_start, child, nothing))
                    scen_start[child] = scen_end[scen]
                else
                    scen_start[child] = min(scen_start[child], scen_end[scen])
                end
            end
            append!(scenarios, children)
        end
    end
    nodal_stochastic_tree = Dict()
    for scen in scenarios
        nodal_stochastic_tree[(node, scen)] = TimeSlice(scen_start[scen], get(scen_end, scen, scen_start[scen])) # TODO: Figure out where the last scenario ends
    end
    return nodal_stochastic_tree
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