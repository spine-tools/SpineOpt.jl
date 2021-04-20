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
function write_model_file(m::Model; file_name="model")

Write model file for Model `m`. Objective, constraints and variable bounds are reported.
Optional argument is keyword `file_name`.
"""
function write_model_file(m::JuMP.Model; file_name="model")
    model_string = "$m"
    model_string = replace(model_string, s": -" => ":- ")
    model_string = replace(model_string, s": " => ": + ")
    model_string = replace(model_string, s"+ " => "\n\t+ ")
    model_string = replace(model_string, s"- " => "\n\t- ")
    model_string = replace(model_string, s">= " => "\n\t\t>= ")
    model_string = replace(model_string, s"== " => "\n\t\t== ")
    model_string = replace(model_string, s"<= " => "\n\t\t<= ")
    open(joinpath(@__DIR__, "$(file_name).so_model"), "w") do file
        write(file, model_string)
    end
end

function print_constraint(constraint, filename="constraint_debug.txt")
    io = open(joinpath(@__DIR__, filename), "w")
    for (inds, con) in constraint
        print(io, inds, "\n")
        print(io, con, "\n\n")
    end
    close(io)
end

function write_conflicts_to_file(conflicts; file_name="conflicts")
    io = open(joinpath(@__DIR__, "$(file_name).txt"), "w")
    for confl in conflicts
        print(io, confl, "\n")
    end
    close(io)
end

"""
    write_ptdfs()

Write `ptdf` parameter values to a `ptdfs.csv` file.
"""
function write_ptdfs()
    io = open("ptdfs.csv", "w")
    print(io, "connection,")
    for n in node(has_ptdf=true)
        print(io, string(n), ",")
    end
    print(io, "\n")
    for conn in connection(has_ptdf=true)
        print(io, string(conn), ",")
        for n in node(has_ptdf=true)
            print(io, ptdf(connection=conn, node=n), ",")
        end
        print(io, "\n")
    end
    close(io)
end

"""
    write_lodfs()

Write `lodf` parameter values to a `lodsfs.csv` file.
"""
function write_lodfs()
    io = open("lodfs.csv", "w")
    print(io, raw"contingency line,from_node,to node,")
    for conn_mon in connection(connection_monitored=true)
        print(io, string(conn_mon), ",")
    end
    print(io, "\n")
    for conn_cont in connection(connection_contingency=true)
        n_from, n_to = connection__from_node(connection=conn_cont, direction=anything)
        print(io, string(conn_cont), ",", string(n_from), ",", string(n_to))
        for conn_mon in connection(connection_monitored=true)
            print(io, ",")
            for (conn_cont, conn_mon) in indices(lodf; connection1=conn_cont, connection2=conn_mon)
                print(io, lodf(connection1=conn_cont, connection2=conn_mon))
            end
        end
        print(io, "\n")
    end
    close(io)
end