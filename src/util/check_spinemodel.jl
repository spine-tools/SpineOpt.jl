#############################################################################
# Copyright (C) 2017 - 2020  Spine Project
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

# The functions in this file utilise PowerSystems.jl to calculate
# power transmission distrivution factors (ptdfs) and line outage
# distribution factors (lodfs). These are used in the power flow
# constraints in SpineOpt
#
#
#

"""
    check_spinemodel(log_level::Int64)

Runs a number of checks to see if the data provided results in a valid model.
"""
function check_spinemodel(log_level::Int64)
    check_islands(log_level)
    check_units_on_resolution()
    check_node__stochastic_structure()
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
                @warn "The network of commodity $(c) consists of multiple islands, this may end badly."
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


"""
    check_units_on_resolution()

Ensures there's exactly one `units_on_resolution` definition per `unit` in the data.
"""
function check_units_on_resolution()
    error_units = []
    for u in unit()
        if length(units_on_resolution(unit=u)) != 1
            push!(error_units, u)
        end
    end
    if !isempty(error_units)
        error(
            """
            Each `unit` must have exactly one `units_on_resolution` defined!
            - Check `units` $(error_units)
            """
        )
    end
end


"""
    check_node__stochastic_structure()

Ensures there's exactly one `node__stochastic_structure` definition per `node` in the data.
"""
function check_node__stochastic_structure()
    error_nodes = []
    for n in node()
        if length(node__stochastic_structure(node=n)) != 1
            push!(error_nodes, n)
        end
    end
    if !isempty(error_nodes)
        error(
            """
            Each `node` must have exactly one `node__stochastic_structure` defined!
            - Check `nodes` $(error_nodes)
            """
        )
    end
end