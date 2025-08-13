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
using CSV
using DataFrames
import DataStructures: OrderedDict

function write_sets_and_variables(mathpath)
    variables = DataFrame(CSV.File(joinpath(mathpath, "variables.csv")))
    variables.variable_name_latex = replace.(variables.variable_name, r"_" => "\\_")
    variables.variable_name_latex .= "``v^{" .* variables.variable_name_latex .* "} ``"
    variables.indices .= replace.(variables.indices, r"_" => "\\_")
    variable_string = "# Variables \n"
    for i in 1:size(variables, 1)
        variable_string = string(variable_string, "## `$(variables.variable_name[i])` \n\n")
        variable_string = string(variable_string, " > **Math symbol:** $(variables.variable_name_latex[i]) \n\n")
        variable_string = string(variable_string, " > **Indices:** $(variables.index[i]) \n\n")
        variable_string = string(variable_string, " > **Indices function:** $(variables.indices[i]) \n\n")
        variable_string = string(variable_string, "$(variables.description[i]) \n\n")
    end
    sets = dropmissing(DataFrame(CSV.File(joinpath(mathpath, "sets.csv"))))
    set_string = "# Sets \n"
    for i in 1:size(sets, 1)
            set_string = string(set_string, "## `$(sets.indices[i])` \n\n")
            set_string = string(set_string, "$(sets.Description[i]) \n\n")
    end
    open(joinpath(mathpath, "variables.md"), "w") do io
        write(io, variable_string)
    end
    open(joinpath(mathpath, "sets.md"), "w") do io
        write(io, set_string)
    end
end

"""
    concept_dictionary(template::Dict; translation::Dict=Dict())

A `Dict` mapping keys from the template ("object_classes", "relationship_classes", etc.)
to another `Dict` mapping 'concept' names ("unit", "node", "unit__from_node", "unit_capacity" etc.)
to a third `Dict` containing information to document that concept.

Unfortunately, the template is not uniform when it comes to the location of the name of each concept, their related
concepts, or the description.
Thus, we have to map things somewhat manually here.
The optional `translation` keyword can be used to aggregate and translate the output.
"""
function concept_dictionary(template::Dict; translation::Dict=Dict())
    # Define mapping of template entries, where each attribute of interest is.
    template_mapping = Dict(
        "object_classes" => Dict(:name => 1, :description => 2),
        "relationship_classes" => Dict(
            :name => 1,
            :description => 3,
            :related_concept => 2,
            :related_concept_type => "object_classes",
        ),
        "parameter_value_lists" => Dict(:name => 1, :possible_values => 2),
        "object_parameters" => Dict(
            :name => 2,
            :parameter_description => 5,
            :related_concept => 1,
            :related_concept_type => "object_classes",
            :default_value => 3,
            :parameter_value_list => 4,
        ),
        "relationship_parameters" => Dict(
            :name => 2,
            :parameter_description => 5,
            :related_concept => 1,
            :related_concept_type => "relationship_classes",
            :default_value => 3,
            :parameter_value_list => 4,
        ),
    )
    # Initialize the concept dictionary based on the template (accumulates entries if overlaps)
    concept_dictionary = Dict()
    for (key, indices) in template_mapping
        translated_key = get(translation, key, key)
        concept_dict_for_key = get!(concept_dictionary, translated_key, Dict())
        for entry in template[key]
            name = entry[indices[:name]]
            concept_dict_for_name = get!(concept_dict_for_key, name, Dict())
            for field in (:description, :parameter_description, :default_value, :parameter_value_list, :possible_values)
                index = get(indices, field, nothing)
                index === nothing && continue
                value = entry[index]
                if field == :default_value
                    value = replace(string(value), "_" => "\\_")
                end
                value === nothing && continue
                if field in (:parameter_description, :default_value, :parameter_value_list)
                    class = "`$(entry[indices[:related_concept]])`"
                    classes_by_value = get!(concept_dict_for_name, field, OrderedDict())
                    push!(get!(classes_by_value, value, []), class)
                elseif field == :possible_values
                    push!(get!(concept_dict_for_name, field, []), value)
                else  # :description
                    concept_dict_for_name[field] = value
                end
            end
            related_concepts = get!(concept_dict_for_name, :related_concepts, Dict())
            related_concept_type = get(indices, :related_concept_type, nothing)
            if !isnothing(related_concept_type)
                related_concept_type = get(translation, related_concept_type, related_concept_type)
                related_concept = entry[indices[:related_concept]]
                if !(related_concept isa Array)
                    related_concept = [related_concept]
                end
                append!(get!(related_concepts, related_concept_type, []), related_concept)
            end
        end
    end
    add_cross_references!(concept_dictionary)
end

"""
    add_cross_references!(concept_dictionary::Dict)

Loops over the `concept_dictionary` and cross-references all `:related_concepts`.
"""
function add_cross_references!(concept_dictionary::Dict)
    # Loop over the concept dictionary and cross-reference all related concepts.
    for (key, concept_dict_for_key) in concept_dictionary
        for (name, concept_dict_for_name) in concept_dict_for_key
            for (related_concept_type, related_concepts) in concept_dict_for_name[:related_concepts]
                for related_concept in related_concepts
                    other_related_concepts = concept_dictionary[related_concept_type][related_concept][:related_concepts]
                    push!(get!(other_related_concepts, key, []), name)
                end
            end
        end
    end
    concept_dictionary
end

"""
    write_concept_reference_files(concept_dictionary::Dict, makedocs_path::String)

Write markdown files for the `Concept Reference` chapter based on the `concept_dictionary`.

Each file is pieced together from two parts: the preamble automatically generated using the
`concept_dictionary`, and a separate description assumed to be found under `docs/src/concept_reference/<name>.md`.
"""
function write_concept_reference_files(concept_dictionary::Dict, makedocs_path::String)
    for (key, concept_dict_for_key) in concept_dictionary
        system_string = ["# $(key)\n\n"]
        # Loop over the unique names and write their information into the filename under a dedicated section.
        for name in unique!(sort!(collect(keys(concept_dict_for_key))))
            concept_dict_for_name = concept_dict_for_key[name]
            section = "\n## `$name`\n\n"
            # If description is defined, include it into the preamble.
            description = get(concept_dict_for_name, :description, nothing)
            if description !== nothing
                section *= "> $description\n\n"
            end
            # If parameter descriptions are defined, include those into the preamble
            classes_by_description = get(concept_dict_for_name, :parameter_description, Dict())
            if length(classes_by_description) == 1
                description = first(collect(keys(classes_by_description)))
                section *= "> $description\n\n"
            elseif !isempty(classes_by_description)
                description = join(
                    ["> - For $(join(classes, ", ")): $desc" for (desc, classes) in classes_by_description], "\n"
                )
                section *= "$description\n\n"
            end
            # If default values are defined, include those into the preamble
            classes_by_default_value = get(concept_dict_for_name, :default_value, Dict())
            if length(classes_by_default_value) == 1
                default_value = first(collect(keys(classes_by_default_value)))
                section *= ">**Default value**: $default_value\n\n"
            elseif !isempty(classes_by_default_value)
                default_value = join(
                    ["> - For $(join(classes, ", ")): $val" for (val, classes) in classes_by_default_value], "\n"
                )
                section *= ">**Default value**:\n$default_value\n\n"
            end
            # If parameter value lists are defined, include those into the preamble
            classes_by_parameter_value_list = get(concept_dict_for_name, :parameter_value_list, Dict())
            if length(classes_by_parameter_value_list) == 1
                parameter_value_list = first(collect(keys(classes_by_parameter_value_list)))
                refstring = string("[$(replace(parameter_value_list, "_" => "\\_"))]", "(@ref)")
                section *= ">**Uses [Parameter Value Lists](@ref):** $refstring\n\n"
            elseif !isempty(classes_by_parameter_value_list)
                parameter_value_list = join(
                    ["> - For $(join(classes, ", ")): $(string("[$(replace(pv_list, "_" => "\\_"))]", "(@ref)"))"
                    for (pv_list, classes) in classes_by_parameter_value_list], "\n"
                )
                section *= ">**Uses [Parameter Value Lists](@ref):**:\n$parameter_value_list\n\n"
            end
            # If possible parameter values are defined, include those into the preamble
            possible_values = unique!(get(concept_dict_for_name, :possible_values, []))
            if !isempty(possible_values)
                strings = ["`$(c)`" for c in possible_values]
                section *= ">**Possible values:** $(join(sort!(strings), ", ", " and ")) \n\n"
            end
            # If related concepts are defined, include those into the preamble
            for (related_concept_type, related_concepts) in concept_dict_for_name[:related_concepts]
                if !isempty(related_concepts)
                    refstrings = ["[$(replace(c, "_" => "\\_"))](@ref)" for c in unique(related_concepts)]
                    section *= string(
                        ">**Related [$(replace(related_concept_type, "_" => "\\_"))](@ref):** ",
                        "$(join(sort!(refstrings), ", ", " and "))\n\n"
                    )
                end
            end
            # Try to fetch the description from the corresponding .md filename.
            description_path = joinpath(makedocs_path, "src", "concept_reference", "$(name).md")
            try
                f = open( description_path, "r")
                description = read(f, String)
            catch
                @warn "extended description for `$name` not found! consider adding one to `$description_path`."
                ""
                description = ""
            end
            push!(system_string, section * description)
        end
        open(joinpath(makedocs_path, "src", "concept_reference", "$(key).md"), "w") do file
            write(file, join(system_string))
        end
    end
end

"""
    populate_empty_chapters!(pages, path)

Expand `pages` in-place so that empty chapters are populated with the entire list of .md files
in the associated folder.

The code assumes a specific structure.
+ All chapters and corresponding markdown files are in the "docs/src folder".
+ folder names need to be lowercase with underscores because folder names are derived from the page names
+ markdown file names can have uppercases and can have underscores but don't need to
  because the page names are derived from file names

Developer note: An alternative approach would be to automatically go over all folders and files
(removing the need for a specific structure), and instead use a list parameter called, e.g., `exclude`,
which indicates which folders and files should be skipped.
To deal with folders in folders we could use walkdir() instead of readdir()
"""
function populate_empty_chapters!(pages, path)
    for (chapname, chapcontent) in pages
        isempty(chapcontent) || continue
        chapdir = lowercase(replace(chapname, " " => "_"))
        fullchapdir = joinpath(path, chapdir)
        isdir(fullchapdir) || continue
        append!(
            chapcontent,
            [
                uppercasefirst(replace(splitext(mdfile)[1], "_" => " ")) => joinpath(chapdir, mdfile)
                for mdfile in readdir(fullchapdir)
                if isfile(joinpath(fullchapdir, mdfile)) && lowercase(splitext(mdfile)[2]) == ".md"
            ]
        )
    end
end

"""
    all_docstrings(m)

A Dict mapping function name to its docstring for given Module.
"""
function all_docstrings(m)
    Dict(
        split(string(binding), ".")[2] => first(values(multidoc.docs)).text
        for (binding, multidoc) in getproperty(m, Base.Docs.META)
    )
end

"""
    expand_tags!(lines, docstrings)

Expand `lines` in place by replacing @@{function name} with the corresponding docstring from `docstrings`,
which must be a `Dict` mapping function names to their docstring.

'''julia
docstrings = all_docstrings(SpineOpt)
lines = [
    "# Constraints",
    "## Auto constraint",
    "@@add_constraint_node_state_capacity!",
)
expand_tags!(lines, docstrings)
'''
"""
function expand_tags!(lines, docstrings)
    replacement_lines = []
    for (k, line) in enumerate(lines)
        if startswith(line, "@@")
            function_name = line[3:end]
            new_lines = docstrings[function_name]
            push!(replacement_lines, (k, new_lines))
        end
    end
    for (k, new_lines) in Iterators.reverse(replacement_lines)
        splice!(lines, k, new_lines)
    end
end
