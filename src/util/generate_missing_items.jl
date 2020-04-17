#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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

# NOTE: these `MissingItemHandler`s come into play whenever the database is missing some of the stuff
# SpineModel expects to find in there.
# The above can happen (i) during development, as we introduce new symbols for novel functionality, and
# (ii) in production, if the user 'accidentally' deletes something.
# I believe SpineModel needs this kind of safeguards to be robust.
# As things stabilize, we should see a correspondance between this
# and what we find in `spinedb_api.create_new_spine_database(for_spine_model=True)`

function generate_missing_items()
    mod = @__MODULE__ 
    classes = Dict{Symbol,Union{ObjectClass,RelationshipClass}}(
        class.name => class for class in object_class(mod)
    )
    merge!(classes, Dict(class.name => class for class in relationship_class(mod)))
    parameters = Set(param.name for param in parameter(mod))
    for name in template["object_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        @warn "object class $name is missing from the db"
        object_class = classes[sym_name] = ObjectClass(sym_name, [])
        @eval mod begin
            $sym_name = $object_class
            export $sym_name
        end
    end
    for (name, object_class_names) in template["relationship_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        @warn "relationship class $name is missing from the db"
        relationship_class = classes[sym_name] = RelationshipClass(sym_name, Symbol.(object_class_names), [])
        @eval mod begin
            $sym_name = $relationship_class
            export $sym_name
        end
    end
    d = Dict{Symbol,Array{Pair{Union{ObjectClass,RelationshipClass},AbstractCallable},1}}()
    for (class_name, name, default_value) in [template["object_parameters"]; template["relationship_parameters"]]
        sym_name = Symbol(name)
        sym_name in parameters && continue
        @warn "parameter $name associated to class $class_name is missing from the db"
        class = classes[Symbol(class_name)]
        default_val = callable(db_api.from_database(JSON.json(default_value)))
        push!(get!(d, sym_name, []), class => default_val)
    end
    for (sym_name, class_default_values) in d
        for (class, default_val) in class_default_values
            for key in keys(class.parameter_values)
                class.parameter_values[key][sym_name] = copy(default_val)
            end
        end
        parameter = Parameter(sym_name, first.(class_default_values))
        @eval mod begin
            $sym_name = $parameter
            export $sym_name
        end
    end
end
