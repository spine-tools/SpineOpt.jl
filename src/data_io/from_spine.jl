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


"""
    JuMP_all_out(db_url)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the database
given by `db_url`. `db_url` is a database url composed according to
[sqlalchemy rules](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls).
See [`JuMP_all_out(db_map::PyObject)`](@ref) for more details.
"""
function JuMP_all_out(db_url; upgrade=false)
    # Create DatabaseMapping object using Python spinedatabase_api
    try
        db_map = db_api[:DatabaseMapping](db_url, upgrade=upgrade)
        JuMP_all_out(db_map)
    catch e
        if isa(e, PyCall.PyError) && pyisinstance(e.val, db_api[:exception][:SpineDBVersionError])
            error(
"""
The database at '$db_url' is from an older version of Spine
and needs to be upgraded in order to be used with the current version.

You can upgrade it by running `JuMP_all_out(db_url; upgrade=true)`.

WARNING: After the upgrade, the database may no longer be used
with previous versions of Spine.
"""
            )
        else
            rethrow()
        end
    end
end

"""
    JuMP_object_out(db_map::PyObject)

Create convenience functions for accessing database
objects e.g. units, nodes or connections

# Example using a convenience function created by calling JuMP_object_out(db_map::PyObject)
```julia
julia> unit()
3-element Array{String,1}:
 "GasPlant"
 "CoalPlant"
 "CHPPlant"
```
"""
function JuMP_object_out(db_map::PyObject)
    # Get all object classes
    object_class_list = py"$db_map.object_class_list()"
    for object_class in py"[x._asdict() for x in $object_class_list]"
        object_class_id = object_class["id"]
        object_class_name = object_class["name"]
        # Get all objects of object_class
        object_list = py"$db_map.object_list(class_id=$object_class_id)"
        object_names = py"[x.name for x in $object_list]"
        object_names = Symbol.(object_names)
        @suppress_err begin
            @eval begin
                # Create convenience function named after the object class
                $(Symbol(object_class_name))() = $(object_names)
                export $(Symbol(object_class_name))
            end
        end
    end
end


"""
    JuMP_relationship_out(db_map::PyObject)

Create convenience functions for accessing relationships
e.g. relationships between units and commodities (unit__commodity) or units and
nodes (unit__node)

# Example using a convenience function created by calling JuMP_object_out(db_map::PyObject)
```julia
julia> unit_node()
9-element Array{Array{String,1},1}:
String["CoalPlant", "BelgiumCoal"]
String["CoalPlant", "LeuvenElectricity"]
String["GasPlant", "BelgiumGas"]
...

julia> unit_node(node="LeuvenElectricity")
1-element Array{String,1}:
 "CoalPlant"
```
"""
function JuMP_relationship_out(db_map::PyObject)
    # Get all relationship classes
    relationship_class_list = py"$db_map.wide_relationship_class_list()"
    # Iterate through relationship classes as dictionaries
    for relationship_class in py"[x._asdict() for x in $relationship_class_list]"
        relationship_class_id = relationship_class["id"]
        relationship_class_name = relationship_class["name"]
        # Generate Array of Strings of object class names in this relationship class
        object_class_name_list = [Symbol(x) for x in split(relationship_class["object_class_name_list"], ",")]
        fix_name_ambiguity!(object_class_name_list)
        relationship_list = py"$db_map.wide_relationship_list(class_id=$relationship_class_id)"
        object_name_lists = Array{Array{Symbol,1},1}()
        for relationship in py"[x._asdict() for x in $relationship_list]"
            object_name_list = [Symbol(x) for x in split(relationship["object_name_list"], ",")]
            push!(object_name_lists, object_name_list)
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(relationship_class_name))(;kwargs...)
                    object_name_lists = $(object_name_lists)
                    object_class_name_list = $(object_class_name_list)
                    indexes = Array{Int64, 1}()
                    object_name_list = Array{Symbol, 1}()
                    for (k, v) in kwargs
                        push!(indexes, findfirst(x -> x == k, object_class_name_list))
                        push!(object_name_list, v)
                    end
                    result = filter(x -> x[indexes] == object_name_list, object_name_lists)
                    slice = filter(i -> !(i in indexes), collect(1:length(object_class_name_list)))
                    length(slice) == 1 && (slice = slice[1])
                    [x[slice] for x in result]
                end
                export $(Symbol(relationship_class_name))
            end
        end
    end
end


"""
    JuMP_object_parameter_out(db_map::PyObject)

Create convenience functions for accessing parameter of objects

# Example using a convenience function created by calling JuMP_object_out(db_map::PyObject)
```julia
    julia> p_UnitCapacity()
    Dict{String,Int64} with 5 entries:
    "ImportGas"  => 10000
    "ImportCoal" => 1000
    "GasPlant"   => 400
    "CHPPlant"   => 200
    "CoalPlant"  => 800

    julia> p_UnitCapacity(unit="GasPlant")
    400
```
"""
function JuMP_object_parameter_out(db_map::PyObject)
    # Get list of all parameter
    parameter_list = py"$db_map.parameter_list()"
    # Iterate through parameters as dictionaries
    for parameter in py"[x._asdict() for x in $parameter_list]"
        parameter_name = parameter["name"]
        # Check whether parameter value is specified at least once
        count_ = py"$db_map.object_parameter_value_list(parameter_name=$parameter_name).count()"
        count_ == 0 && continue
        object_parameter_value_list =
            py"$db_map.object_parameter_value_list(parameter_name=$parameter_name)"
        object_parameter_value_dict = Dict{Symbol,Any}()
        # Loop through all object parameter values to create a Dict(object_name => value, ... )
        # where value is obtained from the json field if possible, else from the value field
        for object_parameter_value in py"[x._asdict() for x in $object_parameter_value_list]"
            object_name = Symbol(object_parameter_value["object_name"])
            value = try
                JSON.parse(object_parameter_value["json"])
            catch LoadError
                as_number(object_parameter_value["value"])
            end
            object_parameter_value_dict[object_name] = value
        end
        @suppress_err begin
            # Create and export convenience functions
            @eval begin
                function $(Symbol(parameter_name))(;t::Union{Int64,Nothing}=nothing, kwargs...)
                    object_parameter_value_dict = $(object_parameter_value_dict)
                    if length(kwargs) == 0
                        # Return dict if kwargs is empty
                        return object_parameter_value_dict
                    elseif length(kwargs) == 1
                        key, value = iterate(kwargs)[1]
                        object_class_name = key  # NOTE: not in use at the moment
                        object_name = value
                        !haskey(object_parameter_value_dict, object_name) && return nothing
                        value = object_parameter_value_dict[object_name]
                        if isa(value, Array)
                            t == nothing && return value
                            return value[t]
                        elseif isa(value, Dict)
                            !haskey(value, "return_expression") && error("Field 'return_expression' not found")
                            return_expression = value["return_expression"]
                            preparation_expressions = get(value, "preparation_expressions", [])
                            for expr in preparation_expressions
                                eval(parse(replace(expr, "\$t" => "$t")))
                            end
                            return eval(parse(replace(return_expression, "\$t" => "$t")))
                        else
                            return value
                        end
                    else # length of kwargs is > 1
                        error("Too many arguments in function call (expected 1, got $(length(kwargs)))")
                    end
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end


"""
    JuMP_relationship_parameter_out(db_map::PyObject)

Create convenience functions for accessing parameters attached to relationships.
Parameter values are accessed using the object names as inputs:

# Example using a convenience function created by calling JuMP_object_out(db_map::PyObject)
```julia
julia> p_TransLoss(connection="EL1", node1="LeuvenElectricity", node2="AntwerpElectricity")
0.9
julia> p_TransLoss(connection="EL1", node1="AntwerpElectricity", node2="LeuvenElectricity")
0.88
```
"""
function JuMP_relationship_parameter_out(db_map::PyObject)
    # Get list of all parameters via spinedata_api
    parameter_list = py"$db_map.parameter_list()"
    # Iterate through parameters as dictionaries
    for parameter in py"[x._asdict() for x in $parameter_list]"
        parameter_name = parameter["name"]
        parameter_id = parameter["id"]
        # Check whether parameter value is specified at least once
        count_ = py"$db_map.relationship_parameter_value_list(parameter_name=$parameter_name).count()"
        count_ == 0 && continue
        relationship_parameter_list =
            py"$db_map.relationship_parameter_list(parameter_id=$parameter_id)"
        # Get object_class_name_list from first row in the result, e.g. ["unit", "node"]
        object_class_name_list = nothing
        for relationship_parameter in py"[x._asdict() for x in $relationship_parameter_list]"
            object_class_name_list = [
                Symbol(x) for x in split(relationship_parameter["object_class_name_list"], ",")
            ]
            break
        end
        # Rename entries of this list by appending increasing integer values if entry occurs more than one time
        fix_name_ambiguity!(object_class_name_list)
        relationship_parameter_value_list =
            py"$db_map.relationship_parameter_value_list(parameter_name=$parameter_name)"
        relationship_parameter_value_dict = Dict{Array{Symbol,1},Any}()
        # Loop through all relationship parameter values to create a Dict("obj1,obj2,.." => value, ... )
        # where value is obtained from the json field if possible, else from the value field
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_name_list = Symbol.(split(relationship_parameter_value["object_name_list"], ",")) #"obj1,obj2,..." e.g. "CoalPlant,Electricity,Coal"
            value = try
                JSON.parse(relationship_parameter_value["json"])
            catch LoadError
                as_number(relationship_parameter_value["value"])
            end
            relationship_parameter_value_dict[object_name_list] = value
        end
        @suppress_err begin
            # Create and export convenience function named as the parameter
            @eval begin
                function $(Symbol(parameter_name))(;t::Union{Int64,Nothing}=nothing, kwargs...)
                    relationship_parameter_value_dict = $(relationship_parameter_value_dict)
                    object_class_name_list = $(object_class_name_list)
                    # If no kwargs are provided a dict of all parameter values is returned
                    if length(kwargs) == 0
                         return relationship_parameter_value_dict
                    end
                    object_name_list = Array{Symbol}(undef, length(kwargs))
                    for (k, v) in kwargs
                        object_name_list[findfirst(x -> x == k, object_class_name_list)] = v
                    end
                    !haskey(relationship_parameter_value_dict, object_name_list) && return nothing
                    value = relationship_parameter_value_dict[object_name_list]
                    if isa(value, Array)
                        t == nothing && return value
                        return value[t]
                    elseif isa(value, Dict)
                        !haskey(value, "return_expression") && error("Field 'return_expression' not found")
                        return_expression = value["return_expression"]
                        preparation_expressions = get(value, "preparation_expressions", [])
                        for expr in preparation_expressions
                            eval(parse(replace(expr, "\$t" => "$t")))
                        end
                        return eval(parse(replace(return_expression, "\$t" => "$t")))
                    else
                        return value
                    end
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end

"""
    JuMP_all_out(db_map::PyObject)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the
database given by `db_map` (see usage below). `db_map` is an instance of `DiffDatabaseMapping`
provided by [`spinedatabase_api`](https://github.com/Spine-project/Spine-Database-API).

Usage:

  - **object class**: call `object_class()` to get the set of objects of class `object_class`.
  - **relationship class**: call `relationship_class()` to get the set of object-tuples related
    under `relationship_class`;
    alternatively, call `relationship_class(object_class=:object)` to get the
    set of object-tuples related to `object`.
  - **parameter**: call `parameter(object_class=:object)` to get the value of
    `parameter` for `object`, which is of class `object_class`.
    If value is an `Array`, then call `parameter(object_class=:object, t=t)` to get
    position `t`.

# Example
```julia
julia> JuMP_all_out("sqlite:///examples/data/testsystem2_v2_multiD_out.sqlite")
julia> commodity()
3-element Array{String,1}:
 "coal"
 "gas"
...
julia> unit_node()
9-element Array{Array{String,1},1}:
String["CoalPlant", "BelgiumCoal"]
String["CoalPlant", "LeuvenElectricity"]
...
julia> conversion_cost(unit="gas_import")
12
julia> demand(node="Leuven", t=17)
700
julia> trans_loss(connection="EL1", node1="LeuvenElectricity", node2="AntwerpElectricity")
0.9
```
"""
function JuMP_all_out(db_map::PyObject)
    JuMP_object_out(db_map)
    JuMP_relationship_out(db_map)
    JuMP_object_parameter_out(db_map)
    JuMP_relationship_parameter_out(db_map)
end
