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

# The functions in this file utilise PowerSystems.jl to calculate
# power transmission distrivution factors (ptdfs) and line outage
# distribution factors (lodfs). These are used in the power flow
# constraints in SpineModel
#
#
#

"""
    process_network()

Main function which is called in run_spine_model.jl to caluate PTDFs, LODFs and network diagnostics

"""

function process_network(log_level)

    level0 = log_level >= 0
    level1 = log_level >= 1
    level2 = log_level >= 2
    level3 = log_level >= 3

    for c in commodity()
        if commodity_physics(commodity=c) in (:commodity_physics_ptdf, :commodity_physics_lodf)

            @log     level2 "Processing network for commodity $(c) with network_physics $(commodity_physics(commodity=c))"
            @logtime level3 "Checking network for islands" n_islands, island_node = islands()
            @log     level3 "Your network consists of $(n_islands) islands"
            if n_islands > 1
                @warn "Your network consists of multiple islands, this may end badly."
#                print(island_node)
            end

            net_inj_nodes=get_net_inj_nodes() # returns list of nodes that have demand and/or generation

            @logtime level3 "calculating ptdfs" ptdf_conn_n = calculate_ptdfs()
            if commodity_physics(commodity = c) == :commodity_physics_lodf
                con__mon = Tuple{Object,Object}[]
                @logtime level3 "calculating lodfs"  lodf_con_mon = calculate_lodfs(ptdf_conn_n, con__mon)
            end
        end
    end
end


"""
    islands()

Determines the number of islands in a commodity network - used for diagnostic purposes

"""
function islands()
    visited_d = Dict{Object,Bool}()
    island_node = Dict{Int64,Array}()
    island = 0

    for c in commodity()
        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
            for n in node__commodity(commodity=c)
                visited_d[n] = false
            end
        end
    end

    for c in commodity()
        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
            for n in node__commodity(commodity=c)
                if !visited_d[n]
                    island = island + 1
                    island_node[island] = Object[]
                    visit(n, island, visited_d, island_node)
                end
            end
        end
    end
    return island, island_node
end

"""
    visit()

Function called recursively to visit nodes in the network to determine number of islands

"""
function visit(n, island, visited_d, island_node)
    visited_d[n] = true
    push!(island_node[island], n)
    for (conn, n2) in connection__node__node(node1=n)
        if !visited_d[n2]
            visit(n2, island, visited_d, island_node)
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
    calculate_ptdfs()

Returns a dict indexed on tuples of (connection, node) containing the ptdfs of the system currently in memory.

"""
function calculate_ptdfs()
    ps_busses = Bus[]
    ps_lines = Line[]

    node_ps_bus  =Dict{Object,Bus}()
    i = 1
    for c in commodity()
        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
            for n in node__commodity(commodity=c)
                if node_opf_type(node=n) == :node_opf_type_reference
                    bustype = BusTypes.REF
                else
                    bustype = BusTypes.PV
                end
                ps_bus = Bus(
                    number = i,
                    name = string(n),
                    bustype = bustype,
                    angle = 0.0,
                    voltage = 0.0,
                    voltagelimits = (min = 0.0, max = 0.0),
                    basevoltage = nothing,
                    area = nothing,
                    load_zone = LoadZone(nothing),
                    ext = Dict{String, Any}()
                )

                push!(ps_busses,ps_bus)
                node_ps_bus[n] = ps_bus
                i = i + 1
            end

            PowerSystems.buscheck(ps_busses)
            PowerSystems.slack_bus_check(ps_busses)

            for conn in connection()
                for (n_from, n_to) in connection__node__node(connection=conn)
                    for c in node__commodity(node=n_from)
                        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
                            ps_arc = Arc(node_ps_bus[n_from], node_ps_bus[n_to])
                            new_line = Line(;
                                name = string(conn),
                                available = true,
                                activepower_flow = 0.0,
                                reactivepower_flow = 0.0,
                                arc = ps_arc,
                                r = connection_resistance(connection=conn),
                                x = max(connection_reactance(connection=conn), 0.00001),
                                b = (from=0.0, to=0.0),
                                rate = 0.0,
                                anglelimits = (min = 0.0, max = 0.0)
                            )

                            push!(ps_lines,new_line)
                        end  #in case there are somehow multiple commodities
                        break
                    end
                    break     #the line is defined in both directions, but PowerSystems.jl only needs it in one.
                end
            end
        end
    end

    ps_ptdf=PowerSystems.PTDF(ps_lines,ps_busses)

    ptdf=Dict{Tuple{Object,Object},Float64}()

    for c in commodity()
        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
            for n in node__commodity(commodity=c)
                for conn in connection()
                    ptdf[(conn,n)] = ps_ptdf[string(conn), node_ps_bus[n].number]
                end
            end
        end
    end

    return ptdf

    #buildlodf needs to be updated to account for cases
    #lodfs=PowerSystems.buildlodf(ps_lines,ps_busses)
end

#function (ptdf::PTDF)(conn::Object, n::Object)
#     # Do something with ptdf, conn, and n, and return the value
#
#     return ptdf[string(conn),string(n)]
#end



"""
    calculate_lodfs(ptdf_b_n, b_con__b_mon)

Returns lodfs for the system specified by ptdf_b_n ,b_con__b_mon as a dict of tuples: contingent_line, monitored_line

"""
# This function takes a long time. PowerSystems has a function that does it faster using linear algebra but doesn't handle the case of tails like
# I would like.

function calculate_lodfs(ptdf_conn_n, con__mon)
    lodf_con_mon = Dict{Tuple{Object,Object},Float64}()
    considered_contingencies = 0
    skipped = 0
    tolerance = 0
    for conn_con in connection()
        if connection_contingency(connection = conn_con) == 1
            for (n_from, n_to) in connection__node__node(connection=conn_con)
                demoninator = 1 - (ptdf_conn_n[(conn_con, n_from)]-ptdf_conn_n[(conn_con, n_to)])
                if abs(demoninator) < 0.001
                    demoninator = -1
                end
                for conn_mon in connection()
                    if connection_monitored(connection=conn_mon) == 1 && conn_con != conn_mon
                        if demoninator == -1
                            lodf_trial = (ptdf_conn_n[(conn_mon, n_from)] - ptdf_conn_n[(conn_mon, n_to)]) / demoninator
                        else
                            lodf_trial = -ptdf_conn_n[(conn_mon, n_from)]
                        end
                        c = first(indices(commodity_lodf_tolerance))
                        tolerance = commodity_lodf_tolerance(commodity=c)
                        if abs(lodf_trial) > tolerance
                            considered_contingencies = considered_contingencies + 1
                            push!(con__mon, (conn_con, conn_mon))
                            lodf_con_mon[(conn_con, conn_mon)] = lodf_trial
                        else
                            skipped = skipped + 1
                        end
                    end
                end
            end
        end
    end
    #@info "Contingencies summary " considered_contingencies skipped tolerance
    return lodf_con_mon
end

function get_net_inj_nodes()
    net_inj_nodes = []
    for c in commodity()
        if commodity_physics(commodity=c) in(:commodity_physics_lodf, :commodity_physics_ptdf)
            for n in node__commodity(commodity=c)
                for u in unit__to_node(node=n)
                    if !(n in net_inj_nodes)
                        push!(net_inj_nodes, n)
                    end
                end
                for u in unit__from_node(node=n)
                    if !(n in net_inj_nodes)
                        push!(net_inj_nodes, n)
                    end
                end
                for ng in node_group__node(node2=n)
                    if fractional_demand(node1=ng, node2=n) > 0 || demand(node=n) > 0
                        if !(n in net_inj_nodes)
                            push!(net_inj_nodes, n)
                        end
                    end
                end
            end
        end
    end
    return net_inj_nodes
end


function write_ptdfs(ptdfs, net_inj_nodes)
    io = open("ptdfs.csv", "w")
    print(io, "connection,")
    for n in net_inj_nodes
        print(io, string(n), ",")
    end
    print(io, "\n")
    for conn in connection(connection_monitored=:true)
        print(io, string(conn), ",")
        for n in net_inj_nodes
            print(io, ptdfs[(conn,n)], ",")
        end
        print(io, "\n")
    end
    close(io)
end
