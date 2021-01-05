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
    model_string = replace(model_string, s"+ " => "\n\t+ ")
    model_string = replace(model_string, s"- " => "\n\t- ")
    model_string = replace(model_string, s">= " => "\n\t\t>= ")
    model_string = replace(model_string, s"== " => "\n\t\t== ")
    model_string = replace(model_string, s"<= " => "\n\t\t<= ")
    open(joinpath(@__DIR__, "$(file_name).so_model"), "w") do file
        write(file, model_string)
    end
end

function write_concept_reference_file(
    makedocs_path::String,
    filename::String,
    template_sections::Array{String,1},
    title::String;
    template_name_index::Int=1,
    w::Bool=true
)
    error_count = 0
    system_string = ["# $(title)\n\n"]
    for section in template_sections
        for i in 1:length(_template[section])
            name = _template[section][i][template_name_index]
            description_path = joinpath(makedocs_path, "src", "concept_reference", "$(name).md")
            try description = open(f->read(f, String), description_path, "r")
                while description[end-1:end] != "\n\n"
                    description = description*"\n"
                end
                push!(system_string, description)
            catch
                @warn("Description for `$(name)` not found! Please add a description to `$(description_path)`.")
                error_count += 1
                description = "### `$(name)`\n\n TODO\n\n"
                push!(system_string, description)
            end
        end
    end
    system_string = join(system_string)
    if w
        open(joinpath(makedocs_path, "src", "concept_reference", "$(filename)"), "w") do file
            write(file, system_string)
        end
    end
    return error_count
end

function print_constraint(constraint)
    io = open(joinpath(@__DIR__, "constraint_debug.txt"), "w")
    for (inds, con) in constraint
        print(io, inds, "\n")        
        print(io, con, "\n\n")
    end
    close(io);
end
