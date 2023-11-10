#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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

function write_sets_and_variables(mathpath)
    variables = DataFrame(CSV.File(joinpath(mathpath, "variables.csv")))
    variables.variable_name_latex = replace.(variables.variable_name, r"_" => "\\_")
    variables.variable_name_latex .= "``v_{" .* variables.variable_name_latex .* "} ``"
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
    initialize_concept_dictionary(template::Dict; translation::Dict=Dict())

Gathers information from `spineopt_template.json` and forms a `Dict` for the concepts according to `translation`.

Unfortunately, the template is not uniform when it comes to the location of the `name` of each concept, their related
concepts, or the `description`.
Thus, we have to map things somewhat manually here.
The optional `translation` keyword can be used to aggregate and translate the output using the
`translate_and_aggregate_concept_dictionary()` function.
"""
function initialize_concept_dictionary(template::Dict; translation::Dict=Dict())
    # Define mapping of template entries, where each attribute of interest is.
    template_mapping = Dict(
        "object_classes" => Dict(:name_index => 1, :description_index => 2),
        "relationship_classes" => Dict(
            :name_index => 1,
            :description_index => 3,
            :related_concept_index => 2,
            :related_concept_type => "object_classes",
        ),
        "parameter_value_lists" => Dict(:name_index => 1, :possible_values_index => 2),
        "object_parameters" => Dict(
            :name_index => 2,
            :description_index => 5,
            :related_concept_index => 1,
            :related_concept_type => "object_classes",
            :default_value_index => 3,
            :parameter_value_list_index => 4,
        ),
        "relationship_parameters" => Dict(
            :name_index => 2,
            :description_index => 5,
            :related_concept_index => 1,
            :related_concept_type => "relationship_classes",
            :default_value_index => 3,
            :parameter_value_list_index => 4,
        ),
        "tools" => Dict(:name_index => 1, :description_index => 2),
        "features" => Dict(
            :name_index => 2,
            :related_concept_index => 1,
            :related_concept_type => "object_classes",
            :default_value_index => 3,
            :parameter_value_list_index => 4,
        ),
        "tool_features" => Dict(
            :name_index => 1,
            :related_concept_index => 2,
            :related_concept_type => "object_classes",
            :default_value_index => 4,
            :feature_index => 4,
        ),
    )
    # Initialize the concept dictionary based on the template (only preserves the last entry, if overlaps)
    concept_dictionary = Dict(
        key => Dict(
            entry[indices[:name_index]] => Dict(
                :description => get(entry, get(indices, :description_index, -1), nothing),
                :default_value => get(entry, get(indices, :default_value_index, -1), nothing),
                :parameter_value_list => get(entry, get(indices, :parameter_value_list_index, -1), nothing),
                :possible_values => if haskey(indices, :possible_values_index)
                    [entry[indices[:possible_values_index]]]
                else
                    nothing
                end,
                :feature => get(entry, get(indices, :feature_index, -1), nothing),
                :related_concepts => if haskey(indices, :related_concept_index)
                    Dict(
                        indices[:related_concept_type] => if entry[indices[:related_concept_index]] isa Array
                            unique(entry[indices[:related_concept_index]])
                        else
                            [entry[indices[:related_concept_index]]]
                        end
                    )
                else
                    Dict()
                end
            )
            for entry in template[key] 
        )
        for (key, indices) in template_mapping
    )
    # Perform a second pass to cover overlapping entries and throw warnings for conflicts
    for (key, indices) in template_mapping
        for entry in template[key]
            concept = concept_dictionary[key][entry[indices[:name_index]]]
            # Check for conflicts in `description`, `default_value`, `parameter_value_list`, `feature`
            if !isnothing(concept[:description]) && concept[:description] != entry[indices[:description_index]]
                @warn(
                    "`$(entry[indices[:name_index]])` has conflicting `description` across duplicate template entries"
                )
            end
            if !isnothing(concept[:default_value]) && concept[:default_value] != entry[indices[:default_value_index]]
                @warn(
                    "`$(entry[indices[:name_index]])` has conflicting `default_value` across duplicate template entries"
                )
            end
            if (
                    !isnothing(concept[:parameter_value_list])
                    && concept[:parameter_value_list] != entry[indices[:parameter_value_list_index]]
                )
                @warn(
                    "`$(entry[indices[:name_index]])` has conflicting `parameter_value_list` ",
                    "across duplicate template entries"
                )
            end
            if !isnothing(concept[:possible_values]) && !isnothing(entry[indices[:possible_values_index]])
                unique!(push!(concept[:possible_values], entry[indices[:possible_values_index]]))
            end                
            if !isnothing(concept[:feature]) && concept[:feature] != entry[indices[:feature_index]]
                @warn(
                    "`$(entry[indices[:name_index]])` has conflicting `parameter_value_list` ",
                    "across duplicate template entries"
                )
            end
            # Include all unique `concepts` into `related concepts`
            if !isempty(concept[:related_concepts])
                related_concepts = if entry[indices[:related_concept_index]] isa Array
                    unique([entry[indices[:related_concept_index]]...])
                else
                    [entry[indices[:related_concept_index]]]
                end
                unique!(append!(concept[:related_concepts][indices[:related_concept_type]], related_concepts))
            end
        end
    end
    # If translation and aggregation is defined, do that.
    if !isempty(translation)
        concept_dictionary = translate_and_aggregate_concept_dictionary(concept_dictionary, translation)
    end
    concept_dictionary
end

"""
    _unique_merge!(value1, value2)

Merges two values together provided it's possible depending on the type.
"""
unique_merge!(value1::Dict, value2::Dict) = merge!(value1, value2)
unique_merge!(value1::String, value2::String) = value1
unique_merge!(value1::Bool, value2::Bool) = value1
unique_merge!(value1::Array, value2::Array) = unique!(append!(value1, value2))
unique_merge!(value1::Nothing, value2::Nothing) = nothing

"""
    translate_and_aggregate_concept_dictionary(concept_dictionary::Dict, translation::Dict)

Translates and aggregates the concept types of the initialized `concept_dictionary` according to `translation`.

`translation` needs to be a `Dict` with arrays of `String`s corresponding to the template sections mapped to
a `String` corresponding to the translated section name.
If multiple template section names are mapped to a single `String`, the entries are aggregated under that title.
"""
function translate_and_aggregate_concept_dictionary(concept_dictionary::Dict, translation::Dict)
    initial_translation = Dict(
        translation[key] => merge((d1, d2) -> merge(unique_merge!, d1, d2), [concept_dictionary[k] for k in key]...)
        for key in keys(translation)
    )
    translated_concept_dictionary = deepcopy(initial_translation)
    for concept_type in keys(initial_translation)
        for concept in keys(initial_translation[concept_type])
            translated_concept_dictionary[concept_type][concept][:related_concepts] = Dict(
                translation[key] => vcat(
                    [
                        initial_translation[concept_type][concept][:related_concepts][k]
                        for k in key if k in keys(initial_translation[concept_type][concept][:related_concepts])
                    ]...,
                )
                for key in keys(translation)
            )
        end
    end
    translated_concept_dictionary
end

"""
    add_cross_references!(concept_dictionary::Dict)

Loops over the `concept_dictionary` and cross-references all `:related_concepts`.
"""
function add_cross_references!(concept_dictionary::Dict)
    # Loop over the concept dictionary and cross-reference all related concepts.
    for class in keys(concept_dictionary)
        for concept in keys(concept_dictionary[class])
            for related_concept_class in keys(concept_dictionary[class][concept][:related_concepts])
                for related_concept in concept_dictionary[class][concept][:related_concepts][related_concept_class]
                    related_concepts = concept_dictionary[related_concept_class][related_concept][:related_concepts]
                    concepts = get!(related_concepts, class, [])
                    concept in concepts || push!(concepts, concept)
                end
            end
        end
    end
    concept_dictionary
end

"""
    write_concept_reference_files(
        concept_dictionary::Dict,
        makedocs_path::String
    )

Automatically writes markdown files for the `Concept Reference` chapter based on the `concept_dictionary`.

Each file is pieced together from two parts: the preamble automatically generated using the
`concept_dictionary`, and a separate description assumed to be found under `docs/src/concept_reference/<name>.md`.
"""
function write_concept_reference_files(concept_dictionary::Dict, makedocs_path::String)
    error_count = 0
    for filename in keys(concept_dictionary)
        system_string = ["# $(filename)\n\n"]
        # Loop over the unique names and write their information into the filename under a dedicated section.
        for concept in unique!(sort!(collect(keys(concept_dictionary[filename]))))
            section = "## `$(concept)`\n\n"
            # If description is defined, include it into the preamble.
            if !isnothing(concept_dictionary[filename][concept][:description])
                section *= ">$(concept_dictionary[filename][concept][:description])\n\n"
            end
            # If default values are defined, include those into the preamble
            if !isnothing(concept_dictionary[filename][concept][:default_value])
                if concept_dictionary[filename][concept][:default_value] isa String
                    str = replace(concept_dictionary[filename][concept][:default_value], "_" => "\\_")
                else
                    str = concept_dictionary[filename][concept][:default_value]
                end
                section *= ">**Default value:** $(str)\n\n"
            end
            # If parameter value lists are defined, include those into the preamble
            if !isnothing(concept_dictionary[filename][concept][:parameter_value_list])
                refstring = string(
                    "[$(replace(concept_dictionary[filename][concept][:parameter_value_list], "_" => "\\_"))]",
                    "(@ref)"
                )
                section *= ">**Uses [Parameter Value Lists](@ref):** $(refstring)\n\n"
            end
            # If possible parameter values are defined, include those into the preamble
            if !isnothing(concept_dictionary[filename][concept][:possible_values])
                strings = [
                    "`$(c)`" for c in concept_dictionary[filename][concept][:possible_values]
                ]
                section *= ">**Possible values:** $(join(sort!(strings), ", ", " and ")) \n\n"
            end
            # If related concepts are defined, include those into the preamble
            if !isempty(concept_dictionary[filename][concept][:related_concepts])
                for related_concept_type in keys(concept_dictionary[filename][concept][:related_concepts])
                    if !isempty(concept_dictionary[filename][concept][:related_concepts][related_concept_type])
                        refstrings = [
                            "[$(replace(c, "_" => "\\_"))](@ref)"
                            for c in concept_dictionary[filename][concept][:related_concepts][related_concept_type]
                        ]
                        section *= string(
                            ">**Related [$(replace(related_concept_type, "_" => "\\_"))](@ref):** ",
                            "$(join(sort!(refstrings), ", ", " and "))\n\n"
                        )
                    end
                end
            end
            # If features are defined, include those into the preamble
            #=
            if !isnothing(concept_dictionary[filename][concept][:feature])
                section *= string(
                    "Uses [Features](@ref): ",
                    "$(join(replace(concept_dictionary[filename][concept][:feature], "_" => "\\_"), ", ", " and "))\n\n"
                )
            end
            =#
            # Try to fetch the description from the corresponding .md filename.
            description_path = joinpath(makedocs_path, "src", "concept_reference", "$(concept).md")
            try
                description = open(f -> read(f, String), description_path, "r")
                while description[(end - 1):end] != "\n\n"
                    description *= "\n"
                end
                push!(system_string, section * description)
            catch
                @warn("Description for `$(concept)` not found! Please add a description to `$(description_path)`.")
                error_count += 1
                push!(system_string, section * "TODO\n\n")
            end
        end
        system_string = join(system_string)
        open(joinpath(makedocs_path, "src", "concept_reference", "$(filename).md"), "w") do file
            write(file, system_string)
        end
    end
    return error_count
end

"""
    populate_empty_chapters!(pages, path)

Expand `pages` in-place so that empty chapters are populated with the entire list of .md files
in the associated folder.

The code assumes a specific structure.
+ All chapters and corresponding markdownfiles are in the "docs/src folder".
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
    alldocs = Dict()
    for multidoc in values(Base.eval(m, Base.Docs.META))
        for doc_str in values(multidoc.docs)
            binding = doc_str.data[:binding]
            key = split(string(binding), ".")[2]
            value = Base.Docs.doc(binding)
            alldocs[key] = value
        end
    end
    alldocs
end

"""
    _find_fields()

Finds specific fields within a docstring and return them as a single string.
"""
function _find_fields(
    docstring; fields=["formulation", "description"], title="", field_title=false, sep="\n\n", debug_mode=false
)
    parts = []
    if !isempty(title)
        push!(parts, title)
    end
    for field in fields
        if field_title
            push!(parts, field)
        end
        try
            sf1 = findfirst("#$field", string(docstring))[end] + 2
            sf2 = findfirst("#end $field", string(docstring))[1] - 2
            sf = SubString(string(docstring), sf1, sf2)
            push!(parts, sf)
            if debug_mode
                println(sf)
            end
        catch
            if debug_mode
                @warn "Cannot find $field"
                # the error could also be because there is no docstring for constraint but that is a very rare case
                # as there is often at least a dynamic docstring
            end
        end
    end
    join(parts, sep)
end

"""
    expand_instructions!(lines, docstrings)

Expand `lines` in place by replacing instructions with appropriate content from given `docstrings`,
which must be a `Dict` mapping function names to their docstring.

The lines can either be:
+ regular strings: these aren't touched
+ instruction strings: strings within an instruction block, these are replaced by specific content from a docstring.

The instruction block consists of a function name and a list of fields in the docstring of that function.
If the function name is 'all_functions' then it will search all docstrings for the given fields.

Each instruction is separated by two end of line characters.

'''julia
docstrings = all_docstrings(SpineOpt)
lines = [
    "# Constraints",
    "## Auto constraint",
    "#instruction",
    "add_constraint_node_state_capacity!",
    "formulation",
    "#end instruction"
)
expand_instructions!(lines, docstrings)
'''
"""
function expand_instructions!(lines, docstrings)
    function interpret_instruction(function_name, function_fields)
        if function_name == "all_functions"
            for (doc_key, doc_value) in docstrings
                title = ""
                if occursin("add_constraint_", doc_key)
                    # remove add_constraint_ as well as !
                    name = split(doc_key, "add_constraint_")[2][end - 1]
                    title = "### " * replace(uppercasefirst(name), "_" => " ")
                end
                md *= _find_fields(doc_value; fields=function_fields, title=title)
            end
        else
            _find_fields(docstrings[function_name]; fields=function_fields)
        end
    end

    replacement_lines = []
    instructions = []
    for (k, line) in enumerate(lines)
        if occursin("#instruction", line)
            push!(instructions, k)
        elseif occursin("#end instruction", line)
            from_ind, function_name, function_fields... = instructions
            to_ind = k
            push!(replacement_lines, (from_ind:to_ind, interpret_instruction(function_name, function_fields)))
            empty!(instructions)
        elseif !isempty(instructions)
            push!(instructions, line)
        end
    end
    replacement_lines
    for (rng, line) in Iterators.reverse(replacement_lines)
        splice!(lines, rng, [line])
    end
end
