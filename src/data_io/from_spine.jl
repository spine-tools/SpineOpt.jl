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
    JuMP_object_parameter_out(db_map::PyObject)

Create convenience functions for accessing parameters of objects.
Return a dictionary of object subsets.

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
    object_subset_dict = Dict{Symbol,Any}()
    value_list_dict = py"{x.id: x.value_list.split(',') for x in $db_map.wide_parameter_value_list_list()}"
    # Iterate through parameters as dictionaries
    for parameter in py"[x._asdict() for x in $db_map.object_parameter_list()]"
        parameter_name = parameter["parameter_name"]
        object_class_name = parameter["object_class_name"]
        parsed_default_value = parse_value(parameter["default_value"])
        tag_list_str = parameter["parameter_tag_list"]
        tag_list = if tag_list_str isa String
            split(tag_list_str, ",")
        else
            []
        end
        value_list_id = parameter["value_list_id"]
        value_list = if value_list_id != nothing
            value_list_dict[value_list_id]
        else
            []
        end
        # Check if it's constructor, and adjust function name
        is_constructor = (parameter_name == object_class_name)
        function_name = if is_constructor
            Symbol("__" * parameter_name * "__")
        else
            Symbol(parameter_name)
        end
        object_parameter_value_dict = Dict{Symbol,Any}()
        object_names = Array{String,1}()  # To be filled with object names if parameter is a constructor
        object_parameter_value_list =
            py"[x._asdict() for x in $db_map.object_parameter_value_list(parameter_name=$parameter_name)]"
        # Loop through all object parameter values
        for object_parameter_value in object_parameter_value_list
            object_name = object_parameter_value["object_name"]
            is_constructor && push!(object_names, object_name)
            json = object_parameter_value["json"]
            value = object_parameter_value["value"]
            # Add entry to object_parameter_value_dict
            new_value = if json != nothing
                try
                    parse_json(json)
                catch e
                    error(
                        "unable to parse JSON from '$object_name, $parameter_name': "
                        * "$(sprint(showerror, e))"
                    )
                end
            elseif value != nothing
                try
                    parse_time_pattern(value)
                catch e
                    "time_pattern_spec" in tag_list && error(
                        "unable to parse time pattern from '$object_name, $parameter_name': "
                        * "$(sprint(showerror, e))"
                    )
                    parse_value(value)
                end
            else
                parsed_default_value
            end
            object_parameter_value_dict[Symbol(object_name)] = new_value
            # Add entry to object_subset_dict
            !(new_value in value_list) && continue
            dict1 = get!(object_subset_dict, Symbol(object_class_name), Dict{Symbol,Any}())
            dict2 = get!(dict1, Symbol(parameter_name), Dict{Symbol,Any}())
            arr = get!(dict2, Symbol(new_value), Array{Symbol,1}())
            push!(arr, Symbol(object_name))
        end
        @suppress_err begin
            # Create and export convenience functions
            @eval begin
                obj_str = $object_class_name * "object"
                """
                    $($function_name)(;$($object_class_name)::Symbol=$obj_str, t::Union{Int64,String,Nothing}=nothing)

                The value of the parameter '$($parameter_name)' for `$obj_str`.
                The argument `t` can be used, e.g., to retrieve a specific position in the returning array.
                """
                function $(function_name)(;t::Union{Int64,String,Nothing}=nothing, kwargs...)
                    object_parameter_value_dict = $(object_parameter_value_dict)
                    if length(kwargs) == 0
                        # Return dict if kwargs is empty
                        object_parameter_value_dict
                    elseif length(kwargs) == 1
                        key, value = iterate(kwargs)[1]
                        given_object_class_name = key
                        object_class_name = Symbol($object_class_name)
                        given_object_class_name != object_class_name && error(
                            "invalid object class in call to '$($parameter_name)': "
                            * "expected '$object_class_name', got '$given_object_class_name'"
                        )
                        given_object_name = value
                        object_names = eval(object_class_name)()
                        !(given_object_name in object_names) && error(
                            "unable to retrieve value of '$($parameter_name)' for '$given_object_name': "
                            * "not a valid object of class '$object_class_name'"
                        )
                        !haskey(object_parameter_value_dict, given_object_name) && return $parsed_default_value
                        value = object_parameter_value_dict[given_object_name]
                        result = try
                            SpineModel.get_scalar(value, t)
                        catch e
                            error(
                                "unable to retrieve value of '$($parameter_name)' " *
                                "for '$given_object_name': $(sprint(showerror, e))"
                            )
                        end
                        return result
                    else # length of kwargs is > 1
                        error(
                            "too many arguments in call to '$($parameter_name)': "
                            * "expected 1, got $(length(kwargs))"
                        )
                    end
                end
                export $(Symbol(parameter_name))
            end
            # Create constructors
            for object_name in object_names
                kw = Symbol(object_class_name)
                @eval begin
                    $(Symbol(object_name))(;t=nothing) = $(function_name)(;t=t, $(kw)=Symbol($object_name))
                    export $(Symbol(object_name))
                end
            end
        end
    end
    object_subset_dict
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
function JuMP_object_out(db_map::PyObject, object_subset_dict::Dict{Symbol,Any})
    # Get all object classes
    object_class_list = py"$db_map.object_class_list()"
    for object_class in py"[x._asdict() for x in $object_class_list]"
        object_class_id = object_class["id"]
        object_class_name = object_class["name"]
        # Get all objects of object_class
        object_list = py"$db_map.object_list(class_id=$object_class_id)"
        object_names = py"[x.name for x in $object_list]"
        object_names = Symbol.(object_names)
        object_subset_dict1 = get(object_subset_dict, Symbol(object_class_name), Dict())
        @suppress_err begin
            @eval begin
                # Create convenience function named after the object class
                function $(Symbol(object_class_name))(;kwargs...)
                    if length(kwargs) == 0
                        # Return all object names if kwargs is empty
                        return $(object_names)
                    else
                        object_class_name = $(object_class_name)
                        # Return the object subset at the intersection of all (parameter, value) pairs
                        # received as arguments
                        kwargs_arr = [par => val for (par, val) in kwargs]
                        par, val = kwargs_arr[1]
                        dict1 = $(object_subset_dict1)
                        !haskey(dict1, par) && error(
                            "unable to retrieve object subset of class '$object_class_name': "
                            * "'$par' is not a list-parameter for '$object_class_name'"
                        )
                        dict2 = dict1[par]
                        !haskey(dict2, val) && error(
                            "unable to retrieve object subset of class '$object_class_name': "
                            * "'$val' is not a listed value for '$par'"
                        )
                        object_subset = dict2[val]
                        for (par, val) in kwargs_arr[2:end]
                            !haskey(dict1, par) && error(
                                "unable to retrieve object subset of class '$object_class_name': "
                                * "'$par' is not a list-parameter for '$object_class_name'"
                            )
                            dict2 = dict1[par]
                            !haskey(dict2, val) && error(
                                "unable to retrieve object subset of class '$object_class_name': "
                                * "'$val' is not a listed value for '$par'"
                            )
                            object_subset_ = dict2[val]
                            object_subset = [x for x in object_subset if x in object_subset_]
                        end
                        return object_subset
                    end
                end
                export $(Symbol(object_class_name))
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
    # Iterate through parameters as dictionaries
    for parameter in py"[x._asdict() for x in $db_map.relationship_parameter_list()]"
        parameter_name = parameter["parameter_name"]
        relationship_class_name = parameter["relationship_class_name"]
        default_value = parse_value(parameter["default_value"])
        orig_object_class_name_list = [Symbol(x) for x in split(parameter["object_class_name_list"], ",")]
        # Rename entries of this list by appending increasing integer values if entry occurs more than one time
        object_class_name_list = fix_name_ambiguity(orig_object_class_name_list)
        relationship_parameter_value_list =
            py"$db_map.relationship_parameter_value_list(parameter_name=$parameter_name)"
        relationship_parameter_value_dict = Dict{Tuple{Symbol,Symbol,Vararg{Symbol}},Any}() # At least two Symbols
        # Loop through all relationship parameter values to create a Dict("obj1,obj2,.." => value, ... )
        # where value is obtained from the json field if possible, else from the value field
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_name_list = Tuple(Symbol.(split(relationship_parameter_value["object_name_list"], ",")))
            value = try
                JSON.parse(relationship_parameter_value["json"])
            catch LoadError
                parse_value(relationship_parameter_value["value"])
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
                    kwargs_length = length(kwargs)
                    kwargs_length == 0 && return relationship_parameter_value_dict
                    # Call the relationship access function to check validity
                    relationship_class_name = Symbol($relationship_class_name)
                    header = eval(relationship_class_name)(;header_only=true, kwargs...)
                    # Check that header is empty
                    !isempty(header) && error(
                        """arguments missing in call to $($parameter_name): '$(join(header, "', '"))'"""
                    )
                    given_object_class_name_list = keys(kwargs)
                    given_object_name_list = values(values(kwargs))
                    indexes = indexin(given_object_class_name_list, object_class_name_list)
                    ordered_object_name_list = given_object_name_list[indexes]
                    !haskey(relationship_parameter_value_dict, ordered_object_name_list) && return $default_value
                    value = relationship_parameter_value_dict[ordered_object_name_list]
                    if isa(value, Array)
                        t == nothing && return value
                        return value[t]
                    elseif isa(value, Dict)
                        !haskey(value, "return_expression") && error("Field 'return_expression' not found")
                        return_expression = value["return_expression"]
                        preparation_expressions = get(value, "preparation_expressions", [])
                        for expr in preparation_expressions
                            eval(Meta.parse(replace(expr, "\$t" => "$t")))
                        end
                        return eval(Meta.parse(replace(return_expression, "\$t" => "$t")))
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
        orig_object_class_name_list = [Symbol(x) for x in split(relationship_class["object_class_name_list"], ",")]
        object_class_name_list = fix_name_ambiguity(orig_object_class_name_list)
        relationship_list = py"$db_map.wide_relationship_list(class_id=$relationship_class_id)"
        object_name_lists = Array{Array{Symbol,1},1}()
        for relationship in py"[x._asdict() for x in $relationship_list]"
            object_name_list = [Symbol(x) for x in split(relationship["object_name_list"], ",")]
            push!(object_name_lists, object_name_list)
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(relationship_class_name))(;header_only=false, kwargs...)
                    object_name_lists = $(object_name_lists)
                    object_class_name_list = $(object_class_name_list)
                    orig_object_class_name_list = $(orig_object_class_name_list)
                    indexes = Array{Int64, 1}()
                    object_name_list = Array{Symbol, 1}()
                    for (object_class_name, object_name) in kwargs
                        index = findfirst(x -> x == object_class_name, object_class_name_list)
                        index == nothing && error(
                            """invalid keyword '$object_class_name' in call to '$($relationship_class_name)': """
                            * """valid keywords are '$(join(object_class_name_list, "', '"))'"""
                        )
                        orig_object_class_name = orig_object_class_name_list[index]
                        object_names = eval(orig_object_class_name)()
                        !(object_name in object_names) && error(
                            "unable to retrieve '$($relationship_class_name)' tuples for '$object_name': "
                            * "not a valid object of class '$orig_object_class_name'"
                        )
                        push!(indexes, index)
                        push!(object_name_list, object_name)
                    end
                    slice = filter(i -> !(i in indexes), collect(1:length(object_class_name_list)))
                    header_only && return object_class_name_list[slice]
                    result = filter(x -> x[indexes] == object_name_list, object_name_lists)
                    length(slice) == 1 && (slice = slice[1])
                    [x[slice] for x in result]
                end
                export $(Symbol(relationship_class_name))
            end
        end
    end
end


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
        db_map = db_api.DatabaseMapping(db_url, upgrade=upgrade)
        JuMP_all_out(db_map)
    catch e
        if isa(e, PyCall.PyError) && pyisinstance(e.val, db_api.exception.SpineDBVersionError)
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
    # TODO: generate function that parses JSON here
    object_subset_dict = JuMP_object_parameter_out(db_map)
    JuMP_object_out(db_map, object_subset_dict)
    JuMP_relationship_parameter_out(db_map)
    JuMP_relationship_out(db_map)
end
