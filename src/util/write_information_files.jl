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

function write_system_components_file(file_name="system_components.md")
    system_string = []
    push!(system_string, "# System Components\n\n")
    for k in ["object_classes"]
        push!(system_string, "## $(k)\n\n")
        for j in 1:length(_template[k])
            push!(system_string, "### `$(_template[k][j][1])`\n\n")
            push!(system_string, "$(_template[k][j][2])\n\n")
        end
    end
    for k in ["relationship_classes"]
        push!(system_string, "## $(k)\n\n")
        for j in 1:length(_template[k])
            push!(system_string, "### `$(_template[k][j][1])`\n\n")
            push!(
                system_string,
                "**Relates object classes:** `$(join([_template[k][j][2]...], repeat([",",], length(_template[k][j][2])-1)...))`\n\n",
            )
            push!(system_string, "$(_template[k][j][3])\n\n")
        end
    end
    for k in ["object_parameters"]
        push!(system_string, "## $(k)\n\n")
        for j in 1:length(_template[k])
            push!(system_string, "### `$(_template[k][j][2])`\n\n")
            push!(system_string, "**Object class:** [`$(_template[k][j][1])`](#$(_template[k][j][1]))\n\n")
            _template[k][j][3] != nothing && push!(system_string, "**Default value:** `$(_template[k][j][3])`\n\n")
            _template[k][j][4] != nothing &&
                push!(system_string, "**Parameter value list:** [`$(_template[k][j][4])`](#$(_template[k][j][4]))\n\n")
            _template[k][j][5] != nothing && push!(system_string, "$(_template[k][j][5])\n\n")
        end
    end
    for k in ["relationship_parameters"]
        push!(system_string, "## $(k)\n\n")
        for j in 1:length(_template[k])
            push!(system_string, "### `$(_template[k][j][2])`\n\n")
            push!(system_string, "**Relationship class**: [`$(_template[k][j][1])`](#$(_template[k][j][1]))\n\n")
            _template[k][j][3] != nothing && push!(system_string, "**Default value**: `$(_template[k][j][3])`\n\n")
            _template[k][j][4] != nothing &&
                push!(system_string, "**Parameter value list**: [`$(_template[k][j][4])`](#$(_template[k][j][4]))\n\n")
            _template[k][j][5] != nothing && push!(system_string, "$(_template[k][j][5])\n\n")
        end
    end
    for k in ["parameter_value_lists"]
        push!(system_string, "## $(k)\n\n")
        for j in 1:length(_template[k])
            #unique([x[1] for x in _template["parameter_value_lists" ,]])
            if j > 1 && _template[k][j][1] == _template[k][j-1][1]
                _template[k][j][2] != nothing && push!(system_string, "**Value**: `$(_template[k][j][2])`\n\n")
            else
                push!(system_string, "### `$(_template[k][j][1])`\n\n")
                _template[k][j][2] != nothing && push!(system_string, "**Value**: `$(_template[k][j][2])`\n\n")
            end

        end
    end
    system_string = join(system_string)
    # system_string = replace(system_string, "_" => "\\_")
    open(joinpath(@__DIR__, "$(file_name)"), "w") do file
        write(file, system_string)
    end
end

function print_constraint(constraint)
    io = open(joinpath(@__DIR__, "constraint_debug.txt"), "w")
    for (inds, con) in constraint
        print(io, inds, "\n")        
        print(io, con, "\n\n")
    end
    close(io);
end
