#############################################################################
# Copyright (C) 2017 - 2020  Spine Project
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

# TODO: Check that the stochastic tree is indeed a DAG, with no cycles etc


_check(cond, err_msg) = cond || error(err_msg)

"""
    check_spinemodel(log_level::Int64)

Runs a number of checks to see if the data provided results in a valid model.
"""
function check_spinemodel(log_level::Int64)
    check_model_object()
    check_temporal_block_object()
    check_units_on_resolution()
    check_node__stochastic_structure()
    check_islands(log_level)
end


function check_model_object()
    _check(
        !isempty(model()),
        "`model` object not found - please create an object of class `model` in your input database"
    )
end

function check_temporal_block_object()
    _check(
        !isempty(temporal_block()),
        "`temporal_block` object not found - please create an object of class `temporal_block` in your input database"
    )
end

"""
    check_units_on_resolution()

Ensure there's exactly one `units_on_resolution` definition per `unit` in the data.
"""
function check_units_on_resolution()
    error_units = [u for u in unit() if length(units_on_resolution(unit=u)) != 1]
    _check(
        isempty(error_units),
        "missing `units_on_resolution` relationship for `unit`(s): $(join(error_units, ", ", " and ")) "
        * "- please check your input db"
    )
end

"""
    check_node__stochastic_structure()

Ensure there's exactly one `node__stochastic_structure` definition per `node` in the data.
"""
function check_node__stochastic_structure()
    error_nodes = [n for n in node() if length(node__stochastic_structure(node=n)) != 1]
    _check(
        isempty(error_nodes),
        "missing `node__stochastic_structure` relationship for `node`(s): $(join(error_nodes, ", ", " and ")) "
        * "- please check your input db"

    )
end

"""
    check_islands()

Check network for islands and warn the user if problems.

"""
function check_islands(log_level)

    level0 = log_level >= 0
    level1 = log_level >= 1
    level2 = log_level >= 2
    level3 = log_level >= 3

    for c in commodity()
        if commodity_physics(commodity=c) in (:commodity_physics_ptdf, :commodity_physics_lodf)
            @logtime level3 "Checking network of commodity $(c) for islands" n_islands, island_node = islands(c)
            @log     level3 "The network consists of $(n_islands) islands"
            if n_islands > 1
                @warn "the network of commodity $(c) consists of multiple islands, this may end badly..."
                # add diagnostic option to print island_node which will tell the user which nodes are in which islands
            end
        end
    end
end


"""
    islands()

Determines the number of islands in a commodity network - used for diagnostic purposes

"""
function islands(c)
    visited_d = Dict{Object,Bool}()
    island_node = Dict{Int64,Array}()
    island_count = 0

    for n in node__commodity(commodity=c)
        visited_d[n] = false
    end

    for n in node__commodity(commodity=c)
        if !visited_d[n]
            island_count = island_count + 1
            island_node[island_count] = Object[]
            visit(n, island_count, visited_d, island_node)
        end
    end
    island_count, island_node
end


"""
    visit()

Function called recursively to visit nodes in the network to determine number of islands

"""
function visit(n, island_count, visited_d, island_node)
    visited_d[n] = true
    push!(island_node[island_count], n)
    for (conn, n2) in connection__node__node(node1=n)
        if !visited_d[n2]
            visit(n2, island_count, visited_d, island_node)
        end
    end
end


"""
    check_x()

Check for low reactance values

"""
function check_x()
    @info "Checking reactances"
    for conn in connection()
        if conn_reactance(connection=conn) < 0.0001
            @info "Low reactance may cause problems for line " conn
        end
    end
end

