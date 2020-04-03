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

"""
A type to handle missing db items.
"""
struct MissingItemHandler
    name::Symbol
    value::Any
    handled::Ref{Bool}
    MissingItemHandler(name, value) = new(name, value, false)
end

function (item::MissingItemHandler)(args...; kwargs...)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    item.value
end

function SpineInterface.indices(item::MissingItemHandler; kwargs...)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    ()
end

function Base.getproperty(item::MissingItemHandler, prop::Symbol)
    prop in (:name, :value, :handled) && return getfield(item, prop)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    []
end

_parse_value(value::Nothing) = value
_parse_value(value::Bool) = value
_parse_value(value::Int64) = value
_parse_value(value::Float64) = value
_parse_value(value::String) = value
_parse_value(value::Array) = value
_parse_value(value::Dict) = SpineInterface.db_api.from_database(JSON.json(value)).value


function generate_missing_item_handlers()
    template_path = joinpath(dirname(pathof(@__MODULE__)), "..", "data", "spine_model_template.json")
    template = JSON.parsefile(template_path)
    for name in template["object_classes"]
        symname = Symbol(name)
        quoted_name = Expr(:quote, symname)
        @eval $symname = MissingItemHandler($quoted_name, [])
    end
    for (name, object_class_names) in template["relationship_classes"]
        symname = Symbol(name)
        quoted_name = Expr(:quote, symname)
        @eval $symname = MissingItemHandler($quoted_name, [])
    end
    for (class_name, name, default_value) in [template["object_parameters"]; template["relationship_parameters"]]
        symname = Symbol(name)
        parsed_value = _parse_value(default_value)
        quoted_name = Expr(:quote, symname)
        @eval $symname = MissingItemHandler($quoted_name, $parsed_value)
    end
end
