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
    generate_missing_items()

Compare the defined sets of `ObjectClass`, `RelationshipClass` and parameter definitions with the
`spineopt_template.json` and generates missing items.
"""
function generate_missing_items(mod=@__MODULE__)
    template = SpineOpt.template()
    missing_items = Dict(
        "object classes" => String[],
        "relationship classes" => String[],
        "parameter definitions" => String[],
    )
    classes = Dict{Symbol,Union{ObjectClass,RelationshipClass}}(class.name => class for class in object_class(mod))
    merge!(classes, Dict(class.name => class for class in relationship_class(mod)))
    parameters = Set(param.name for param in parameter(mod))
    for (name,) in template["object_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        push!(missing_items["object classes"], name)
        object_class = classes[sym_name] = ObjectClass(sym_name, [])
        @eval mod begin
            $sym_name = $object_class
            export $sym_name
        end
    end
    for (name, object_class_names) in template["relationship_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        push!(missing_items["relationship classes"], name)
        relationship_class = classes[sym_name] = RelationshipClass(sym_name, Symbol.(object_class_names), [])
        @eval mod begin
            $sym_name = $relationship_class
            export $sym_name
        end
    end
    d = Dict{Symbol,Array{Pair{Union{ObjectClass,RelationshipClass},AbstractParameterValue},1}}()
    for (class_name, name, default_value) in [template["object_parameters"]; template["relationship_parameters"]]
        sym_name = Symbol(name)
        sym_name in parameters && continue
        push!(missing_items["parameter definitions"], string(class_name, ".", name))
        class = classes[Symbol(class_name)]
        default_val = parameter_value(parse_db_value(JSON.json(default_value)))
        push!(get!(d, sym_name, []), class => default_val)
    end
    for (sym_name, class_default_values) in d
        for (class, default_val) in class_default_values
            class.parameter_defaults[sym_name] = copy(default_val)
        end
        parameter = Parameter(sym_name, first.(class_default_values))
        @eval mod begin
            $sym_name = $parameter
            export $sym_name
        end
    end
    header_size = maximum(length(key) for key in keys(missing_items))
    empty_header = repeat(" ", header_size)
    splitter = repeat(" ", 2)
    missing_items_str = ""
    for (key, value) in missing_items
        isempty(value) && continue
        header = lpad(key, header_size)
        missing_items_str *= "\n" * string(header, splitter, value[1], "\n")
        missing_items_str *= join([string(empty_header, splitter, x) for x in value[2:end]], "\n") * "\n"
    end
    if !isempty(missing_items_str)
        println()
        @warn """
        Some items are missing from the input database.
        We'll assume sensitive defaults for any missing parameter definitions, and empty collections for any missing classes.
        SpineOpt might still be able to run, but otherwise you'd need to check your input database.

        Missing item list follows:
        $missing_items_str
        """
    end
end
