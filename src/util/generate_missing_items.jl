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
    classes = Dict{Symbol,Union{ObjectClass,RelationshipClass}}(class.name => class for class in object_class(@__MODULE__))
    merge!(classes, Dict(class.name => class for class in relationship_class(@__MODULE__)))
    parameters = Set(param.name for param in parameter(@__MODULE__))
    for name in template["object_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        @warn "Object class $sym_name is missing from the db."
        object_class = ObjectClass(sym_name, [])
        @eval $sym_name = $object_class
    end
    for (name, object_class_names) in template["relationship_classes"]
        sym_name = Symbol(name)
        sym_name in keys(classes) && continue
        @warn "Relationship class $sym_name is missing from the db."
        relationship_class = RelationshipClass(sym_name, Symbol.(object_class_names), [])
        @eval $sym_name = $relationship_class
    end
    for (class_name, name, default_value) in [template["object_parameters"]; template["relationship_parameters"]]
        sym_name = Symbol(name)
        sym_name in parameters && continue
        @warn "Parameter $sym_name is missing from the db."
        sym_class_name = Symbol(class_name)
        class = classes[sym_class_name]
        default_val = callable(db_api.from_database(JSON.json(default_value)))
        parameter = Parameter(sym_name, Dict(class => default_val))
        @eval $sym_name = $parameter
    end
end
