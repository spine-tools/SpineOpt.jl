"""
    JuMP_all_out(db_url)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the database
given by `db_url`. `db_url` is a database url composed according to
[sqlalchemy rules](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls).
See [`JuMP_all_out(db_map::PyObject)`](@ref) for details
about the generated convenience functions.
"""
function JuMP_all_out(db_url)
    # Create DatabaseMapping object using Python spinedatabase_api
    db_map = db_api[:DatabaseMapping](db_url)
    JuMP_all_out(db_map)
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
        object_class_name_list = [String(x) for x in split(relationship_class["object_class_name_list"], ",")]
        fix_name_ambiguity!(object_class_name_list)
        relationship_list = py"$db_map.wide_relationship_list(class_id=$relationship_class_id)"
        object_name_lists = Array{Array{String,1},1}()
        for relationship in py"[x._asdict() for x in $relationship_list]"
            object_name_list = [String(x) for x in split(relationship["object_name_list"], ",")]
            push!(object_name_lists, object_name_list)
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(relationship_class_name))(;kwargs...)
                    result = $(object_name_lists)
                    object_class_name_list = $(object_class_name_list)
                    object_class_name_list_temp = copy(object_class_name_list)
                    for (key,value) in kwargs
                        index = findfirst(x -> x == string(key), object_class_name_list_temp)
                        result = filter(x -> x[index] == value, result)
                        result = [x[1:end .!= index] for x in result]
                        # Update index for next loop
                        filter!(e -> e ≠ object_class_name_list[index], object_class_name_list_temp)
                        # FIXME: do we need to compute index here? We do it above...
                        index = findfirst(x -> x == string(key), object_class_name_list_temp)
                    end
                    [size(x, 1) == 1?x[1]:x for x in result]
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
        object_parameter_value_dict = Dict{String,Any}()
        # Loop through all object parameter values to create a Dict(object_name => value, ... )
        # where value is obtained from the json field if possible, else from the value field
        for object_parameter_value in py"[x._asdict() for x in $object_parameter_value_list]"
            object_name = object_parameter_value["object_name"]
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
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    # length(kwargs) != 1 && return nothing
                    object_parameter_value_dict = $(object_parameter_value_dict)
                    if length(kwargs)==0
                        # Return dict if kwargs is empty
                        return object_parameter_value_dict
                    # Return position t of value for object given in kwargs if Array, else return value
                    elseif length(kwargs) == 1
                        key, value = kwargs[1]
                        object_class_name = string(key)  # NOTE: not in use at the moment
                        object_name = value
                        !haskey(object_parameter_value_dict, object_name) && return nothing
                        value = object_parameter_value_dict[object_name]
                        if isa(value, Array)
                            return value[t]
                        else
                            return value
                        end
                    # If length of kwargs is > 1 function call contains an error
                    else
                        return nothing
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
                String(x) for x in split(relationship_parameter["object_class_name_list"], ",")
            ]
            break
        end
        # Rename entries of this list by appending increasing integer values if entry occurs more than one time
        fix_name_ambiguity!(object_class_name_list)
        relationship_parameter_value_list =
            py"$db_map.relationship_parameter_value_list(parameter_name=$parameter_name)"
        relationship_parameter_value_dict = Dict{String,Any}()
        # Loop through all relationship parameter values to create a Dict("obj1,obj2,.." => value, ... )
        # where value is obtained from the json field if possible, else from the value field
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_name_list = relationship_parameter_value["object_name_list"] #"obj1,obj2,..." e.g. "CoalPlant,Electricity,Coal"
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
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    relationship_parameter_value_dict = $(relationship_parameter_value_dict)
                    object_class_name_list = $(object_class_name_list)
                    # If no kwargs are provided a dict of all parameter values is returned
                    if length(kwargs) == 0
                         return relationship_parameter_value_dict
                    end
                    # Create list of valid object class names
                    kwargs_dict = Dict(kwargs)
                    object_name_list = Array{String,1}()
                    for object_class_name in object_class_name_list
                        if haskey(kwargs_dict, Symbol(object_class_name))
                            push!(object_name_list, kwargs_dict[Symbol(object_class_name)])
                            continue
                        end
                    end
                    object_name_list = join(object_name_list, ",")
                    !haskey(relationship_parameter_value_dict, object_name_list) && return nothing
                    value = relationship_parameter_value_dict[object_name_list]
                    if isa(value, Array)
                        return value[t]
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
database given by `db_map`. `db_map` is an instance of `DatabaseMapping`
provided by [`spinedatabase_api`](https://gitlab.vtt.fi/spine/data/tree/database_api).
The convenience functions are called as follows:

  - **object class**: call `x()` to get the set of names of objects of the class named `x`.
  - **relationship class**: call `y()` to get the set of name tuples of objects related by the
    relationship class named `"y"`; also call `y(object_class_name="object_name")` to get the
    set of name tuples of objects related to "object_name".
  - **parameter**: call `z("k", t)` to get the value of the parameter named `"z"` for the object
    named `"k"`, or `Nullable()` if the parameter is not defined.
    If this value is an array in the Spine object, then `z("k", t)` returns position `t` in that array.

# Example
```julia
julia> JuMP_all_out(db_url)

#call object class function
julia> commodity()
3-element Array{String,1}:
 "coal"
 "gas"
...
#call relationship class function
julia> unit_node()
9-element Array{Array{String,1},1}:
String["CoalPlant", "BelgiumCoal"]
String["CoalPlant", "LeuvenElectricity"]
...

#call parameter class function
julia> conversion_cost(unit="gas_import")
12
julia> demand(node="Leuven", t=17)
700
julia> p_TransLoss(connection="EL1", node1="LeuvenElectricity", node2="AntwerpElectricity")
0.9
```
"""
function JuMP_all_out(db_map::PyObject)
    JuMP_object_out(db_map)
    JuMP_relationship_out(db_map)
    JuMP_object_parameter_out(db_map)
    JuMP_relationship_parameter_out(db_map)
end
