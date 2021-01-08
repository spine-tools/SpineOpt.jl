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

"""
    write_concept_reference_file(
        makedocs_path::String,
        filename::String,
        template_sections::Array{String,1},
        title::String;
        template_name_index::Int=1,
        template_related_concept_index::Int=template_name_index,
        template_related_concept_names::Array{String,1}=[""],
        template_default_value_index::Int=template_name_index,
        template_parameter_value_list_index::Int=template_name_index,
        template_description_index::Int=template_name_index,
        w::Bool=true
    )

Automatically writes a markdown file for the `Concept Reference` chapter based on `spineopt_template.json`.

The file is pieced together from three parts: the given `title`, a preamble automatically generated using the
`spineopt_template`, and a separate description assumed to be found under `docs/src/concept_reference/<name>.md`.

The necessary arguments control *how* the file is created. The keywords define how the `spineopt_template.json`
is interpreted, with the exception of the `w` keyword, which is a flag for controlling whether
the files are written or not.
"""
function write_concept_reference_file(
    makedocs_path::String,
    filename::String,
    template_sections::Array{String,1},
    title::String;
    template_name_index::Int=1,
    template_related_concept_index::Int=template_name_index,
    template_related_concept_names::Array{String,1}=[""],
    template_default_value_index::Int=template_name_index,
    template_parameter_value_list_index::Int=template_name_index,
    template_description_index::Int=template_name_index,
    w::Bool=true
)
    error_count = 0
    # Initialize the `system_string` with the desired title and two newlines
    system_string = ["# $(title)\n\n"]
    # Loop over every section to be aggregated into the file and collect unique template entries
    entries = sort!(unique(
        (
            name = _template[section][i][template_name_index],
            related_concept_name = template_related_concept_names[s],
            related_concepts = _template[section][i][template_related_concept_index],
            default_value = _template[section][i][template_default_value_index],
            parameter_value_list = _template[section][i][template_parameter_value_list_index],
            description = _template[section][i][template_description_index]
        )
        for (s,section) in enumerate(template_sections)
        for i in 1:length(_template[section])
    ))
    # Loop over the unique entries and write their information into the file under section `entry.name`
    for entry in entries
        title = "## `$(entry.name)`\n\n"
        preamble = ""
        # If description is defined, include it into the preamble.
        if template_description_index != template_name_index
            preamble *= "$(entry.description)\n\n"
        end
        # If related concepts are defined, include those into the preamble
        if template_related_concept_index != template_name_index
            if entry.related_concepts isa String
                rels = ["[$(replace(entry.related_concepts, "_" => "\\_"))](@ref)"]
            elseif entry.related_concepts isa Array
                rels = ["[$(replace(rel, "_" => "\\_"))](@ref)" for rel in entry.related_concepts]
            else
                rels = []
            end
            preamble *= "Related [$(entry.related_concept_name)](@ref): $(join(rels, ", ", " and "))\n\n"
        end
        # If default values are defined, include those into the preamble
        if template_default_value_index != template_name_index
            preamble *= "Default value: `$(entry.default_value)`\n\n"
        end
        # If parameter value lists are defined, include those into the preamble
        if template_parameter_value_list_index != template_name_index && !isnothing(entry.parameter_value_list)
            preamble *= "Uses [Parameter Value Lists](@ref): [$(replace(entry.parameter_value_list, "_" => "\\_"))](@ref)\n\n"
        end
        # Try to fetch the description from the corresponding .md file.
        description_path = joinpath(makedocs_path, "src", "concept_reference", "$(entry.name).md")
        try description = open(f->read(f, String), description_path, "r")
            while description[end-1:end] != "\n\n"
                description *= "\n"
            end
            push!(system_string, title * preamble * description)
        catch
            @warn("Description for `$(entry.name)` not found! Please add a description to `$(description_path)`.")
            error_count += 1
            push!(system_string, title * preamble * "TODO\n\n")
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
