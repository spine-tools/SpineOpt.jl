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
            entry[template_mapping[key][:name_index]] => Dict(
                :description => isnothing(get(template_mapping[key], :description_index, nothing)) ? nothing :
                                entry[template_mapping[key][:description_index]],
                :default_value => isnothing(get(template_mapping[key], :default_value_index, nothing)) ? nothing :
                                  entry[template_mapping[key][:default_value_index]],
                :parameter_value_list => isnothing(get(template_mapping[key], :parameter_value_list_index, nothing)) ?
                                         nothing : entry[template_mapping[key][:parameter_value_list_index]],
                :possible_values => isnothing(get(template_mapping[key], :possible_values_index, nothing)) ? nothing :
                                    [entry[template_mapping[key][:possible_values_index]]],
                :feature => isnothing(get(template_mapping[key], :feature_index, nothing)) ? nothing :
                            entry[template_mapping[key][:feature_index]],
                :related_concepts => isnothing(get(template_mapping[key], :related_concept_index, nothing)) ? Dict() :
                                     Dict(
                    template_mapping[key][:related_concept_type] => (isa(
                        entry[template_mapping[key][:related_concept_index]],
                        Array,
                    ) ? (unique([
                        entry[template_mapping[key][:related_concept_index]]...,
                    ])) : [
                        entry[template_mapping[key][:related_concept_index]],
                    ]),
                ),
            ) for entry in template[key] 
        ) for key in keys(template) if ! key in ["objects", "relationships", "object_parameter_values", "relationship_parameter_values"]
    )
    # Perform a second pass to cover overlapping entries and throw warnings for conflicts
    for key in keys(template)
        for entry in template[key]
            concept = concept_dictionary[key][entry[template_mapping[key][:name_index]]]
            # Check for conflicts in `description`, `default_value`, `parameter_value_list`, `feature`
            if !isnothing(concept[:description]) &&
               concept[:description] != entry[template_mapping[key][:description_index]]
                @warn "`$(entry[template_mapping[key][:name_index]])` has conflicting `description` across dulipcate template entries!"
            end
            if !isnothing(concept[:default_value]) &&
               concept[:default_value] != entry[template_mapping[key][:default_value_index]]
                @warn "`$(entry[template_mapping[key][:name_index]])` has conflicting `default_value` across dulipcate template entries!"
            end
            if !isnothing(concept[:parameter_value_list]) &&
               concept[:parameter_value_list] != entry[template_mapping[key][:parameter_value_list_index]]
                @warn "`$(entry[template_mapping[key][:name_index]])` has conflicting `parameter_value_list` across dulipcate template entries!"
            end
            if !isnothing(concept[:possible_values]) && !isnothing(entry[template_mapping[key][:possible_values_index]])
                unique!(push!(concept[:possible_values], entry[template_mapping[key][:possible_values_index]]))
            end                
            if !isnothing(concept[:feature]) && concept[:feature] != entry[template_mapping[key][:feature_index]]
                @warn "`$(entry[template_mapping[key][:name_index]])` has conflicting `parameter_value_list` across dulipcate template entries!"
            end
            # Include all unique `concepts` into `related concepts`
            if !isempty(concept[:related_concepts])
                if isa(entry[template_mapping[key][:related_concept_index]], Array)
                    related_concepts = unique([entry[template_mapping[key][:related_concept_index]]...])
                else
                    related_concepts = [entry[template_mapping[key][:related_concept_index]]]
                end
                unique!(
                    append!(concept[:related_concepts][template_mapping[key][:related_concept_type]], related_concepts),
                )
            end
        end
    end
    # If translation and aggregation is defined, do that.
    if !isempty(translation)
        concept_dictionary = translate_and_aggregate_concept_dictionary(concept_dictionary, translation)
    end
    return concept_dictionary
end

"""
    _unique_merge!(value1, value2)

Merges two values together provided it's possible depending on the type.
"""
unique_merge!(value1::Dict, value2::Dict) = merge!(value1, value2)
unique_merge!(value1::String, value2::String) = value1
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
        translation[key] => mergewith(
            (d1, d2) -> mergewith(unique_merge!, d1, d2),
            [concept_dictionary[k] for k in key]...
        )
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
                ) for key in keys(translation)
            )
        end
    end
    return translated_concept_dictionary
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
                    if !isnothing(
                        get(
                            concept_dictionary[related_concept_class][related_concept][:related_concepts],
                            class,
                            nothing,
                        ),
                    )
                        if concept in concept_dictionary[related_concept_class][related_concept][:related_concepts][class]
                            nothing
                        else
                            push!(
                                concept_dictionary[related_concept_class][related_concept][:related_concepts][class],
                                concept,
                            )
                        end
                    else
                        concept_dictionary[related_concept_class][related_concept][:related_concepts][class] = [concept]
                    end
                end
            end
        end
    end
    return concept_dictionary
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
                refstring = "[$(replace(concept_dictionary[filename][concept][:parameter_value_list], "_" => "\\_"))](@ref)"
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
                        section *= ">**Related [$(replace(related_concept_type, "_" => "\\_"))](@ref):** $(join(sort!(refstrings), ", ", " and "))\n\n"
                    end
                end
            end
            # If features are defined, include those into the preamble
            #if !isnothing(concept_dictionary[filename][concept][:feature])
            #    section *= "Uses [Features](@ref): $(join(replace(concept_dictionary[filename][concept][:feature], "_" => "\\_"), ", ", " and "))\n\n"
            #end
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