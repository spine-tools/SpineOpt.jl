#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

function _without_printing_limits(f, m)
    limits = try
        JuMP._CONSTRAINT_LIMIT_FOR_PRINTING[], JuMP._TERM_LIMIT_FOR_PRINTING[]
    catch err
        err isa UndefVarError || rethrow()
        nothing
    end
    limits === nothing && return f()
    con_limit, term_limit = limits
    constraint_functions = [
        jump_function(constraint_object(cref))
        for (F, S) in list_of_constraint_types(m)
        for cref in all_constraints(m, F, S)
    ]
    JuMP._CONSTRAINT_LIMIT_FOR_PRINTING[] = length(constraint_functions)
    JuMP._TERM_LIMIT_FOR_PRINTING[] = maximum(_term_count.(constraint_functions); init=0)
    try
        return f()
    finally
        JuMP._CONSTRAINT_LIMIT_FOR_PRINTING[], JuMP._TERM_LIMIT_FOR_PRINTING[] = con_limit, term_limit
    end
end

function _term_count(x)
    try
        length(x.terms)
    catch
        0
    end
end

function _print_full_model(io::IO, model::AbstractModel)
    # NOTE: If errors originating here, just uncomment the line below to restore printing - although with JuMP limits
    # return println(io, model)
    _without_printing_limits(model) do
        println(io, model)
    end
end

"""
    write_model_file(m; file_name="model")

Write model file for given model.
"""
function write_model_file(m::JuMP.Model; file_name="model")
    model_string = sprint(_print_full_model, m)
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
            ptdf_val = ptdf(connection=conn, node=n, _strict=false)
            if ptdf_val === nothing
                ptdf_val = 0
            end
            print(io, ptdf_val, ",")
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
        # NOTE: always assume that the flow goes from the first to the second node in `connection__from_node`
        # CAUTION: this assumption works only for bi-directional connections with 2 nodes as required in the lodf calculation
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