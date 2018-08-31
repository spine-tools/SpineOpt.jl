"""
    JuMP_all_out(db_url)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the database
given by `db_url`. `db_url` is a database url composed according to
[sqlalchemy rules](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls).
See [`JuMP_all_out(mapping::PyObject)`](@ref) for details
about the generated convenience functions.
"""
function JuMP_all_out(db_url)
    mapping = db_api[:DatabaseMapping](db_url) #creates a DatabaseMapping object using Python spinedatabase_api
    JuMP_all_out(mapping)
end



"""
Append an increasing integer to object classes that are repeated

# Example
```julia
julia> s=["connection","node", "node"]
3-element Array{String,1}:
 "connection"
 "node"
 "node"

julia> SpineModel.fix_name_ambiguity!(s)

julia> s
3-element Array{String,1}:
 "connection"
 "node1"
 "node2"
```
"""
function fix_name_ambiguity!(object_class_name_list)
    ref_object_class_name_list = copy(object_class_name_list)
    object_class_name_ocurrences = Dict{String,Int64}()
    for (i, object_class_name) in enumerate(object_class_name_list)
        n_ocurrences = count(x -> x == object_class_name, ref_object_class_name_list)
        n_ocurrences == 1 && continue
        ocurrence = get(object_class_name_ocurrences, object_class_name, 1)
        object_class_name_list[i] = string(object_class_name, ocurrence)
        object_class_name_ocurrences[object_class_name] = ocurrence + 1
    end
end

"""
JuMP_object_out creates "convenience" functions for accessing database
objects e.g. units, nodes or connections

# Example using a convenience function created by calling JuMP_object_out(mapping::PyObject)
```julia
    julia> unit()
    3-element Array{String,1}:
     "GasPlant"
     "CoalPlant"
     "CHPPlant"
```

"""
function JuMP_object_out(mapping::PyObject)
    object_class_list = py"$mapping.object_class_list()" #getting all object class names
    for object_class in py"[x._asdict() for x in $object_class_list]"
        object_class_id = object_class["id"]
        object_class_name = object_class["name"]
        object_list = py"$mapping.object_list(class_id=$object_class_id)"#getting all objects of object_class
        object_names = py"[x.name for x in $object_list]"
        @suppress_err begin
            @eval begin #creating "convenience" funtion named by the object class name
                $(Symbol(object_class_name))() = $(object_names)
                export $(Symbol(object_class_name))
            end
        end
    end
end


"""
JuMP_relationship_out creates "convenience" functions for accessing relationships
e.g. realtiosnhips between units and commidities (unit__commodity) or units and
nodes (unit__node)

# Example using a convenience function created by calling JuMP_object_out(mapping::PyObject)
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
function JuMP_relationship_out(mapping::PyObject)
    relationship_class_list = py"$mapping.wide_relationship_class_list()"  #getting all relationship class names
    for relationship_class in py"[x._asdict() for x in $relationship_class_list]" #iterating through dict of class names
        relationship_class_id = relationship_class["id"]
        relationship_class_name = relationship_class["name"]
        object_class_name_list = [String(x) for x in split(relationship_class["object_class_name_list"], ",")] #generate Array of strings
        fix_name_ambiguity!(object_class_name_list)
        relationship_list = py"$mapping.wide_relationship_list(class_id=$relationship_class_id)"
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
                    for (key,value) in kwargs
                        index = findfirst(x -> x == string(key), object_class_name_list)
                        # @show string(key)
                        # @show object_class_name_list
                        result = filter(x -> x[index] == value, result)
                        result = [x[1:end .!= index] for x in result]
                    end
                    [size(x, 1) == 1?x[1]:x for x in result]
                end
                export $(Symbol(relationship_class_name))
            end
        end
    end
end


"""
JuMP_object_parameter_out creates "convenience" functions for accessing parameter of objects

# Example using a convenience function created by calling JuMP_object_out(mapping::PyObject)
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
function JuMP_object_parameter_out(mapping::PyObject)
    parameter_list = py"$mapping.parameter_list()" #export list of all parameter names
    for parameter in py"[x._asdict() for x in $parameter_list]" #iterate through dict of parameter names
        parameter_name = parameter["name"]
        count_ = py"$mapping.object_parameter_value_list(parameter_name=$parameter_name).count()"
        count_ == 0 && continue #just export a convinient function if at least one parameter value is set
        object_parameter_value_list =
            py"$mapping.object_parameter_value_list(parameter_name=$parameter_name)"
        object_parameter_value_dict = Dict{String,Any}()
        for object_parameter_value in py"[x._asdict() for x in $object_parameter_value_list]" #looping through all object parameter values to create a Dict(objectname => Dict("json"=>..., "value"=>...), ... )
            object_name = object_parameter_value["object_name"]
            json = try
                JSON.parse(object_parameter_value["json"])
            catch LoadError
                nothing
            end
            value = object_parameter_value["value"]
            object_parameter_value_dict[object_name] = Dict{String,Any}(
                "json" => json,
                "value" => as_number(value)
            )
        end
        @suppress_err begin #creating and exporting convenient functions
            @eval begin
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    # length(kwargs) != 1 && return nothing
                    if length(kwargs)==0 #return dict if kwargs is empty
                         d = Dict(String(key) => v["json"]==nothing?v["value"]:v["json"] for (key, v) in $(object_parameter_value_dict))
                         return d
                    elseif length(kwargs) == 1 #return json of object defined in kwargs if json exist, elso return value
                        key, value = kwargs[1]
                        object_parameter_value_dict = $(object_parameter_value_dict)
                        object_class_name = string(key)  # NOTE: not in use at the moment
                        object_name = value
                        !haskey(object_parameter_value_dict, object_name) && return nothing
                        result = object_parameter_value_dict[object_name]
                        result["json"] == nothing && return result["value"]
                        return result["json"][t]
                    else #if length of kwargs is >1 function call contains an error
                        return nothing
                    end
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end


"""
JuMP_relationship_parameter_out creates "convenience" functions for accessing parameter attached to relationships.

# Example using a convenience function created by calling JuMP_object_out(mapping::PyObject)
```julia

    # parameter values are accessed using the object names is inputs:
    julia> p_TransLoss(connection="EL1", node1="LeuvenElectricity", node2="AntwerpElectricity")
    0.9

    julia> p_TransLoss(connection="EL1", node1="AntwerpElectricity", node2="LeuvenElectricity")
    0.88

```

"""
function JuMP_relationship_parameter_out(mapping::PyObject)
    parameter_list = py"$mapping.parameter_list()" #getting list of all parameter names via spinedata_api
    for parameter in py"[x._asdict() for x in $parameter_list]"#iterate through dict of parameter names
        parameter_name = parameter["name"]
        count_ = py"$mapping.relationship_parameter_value_list(parameter_name=$parameter_name).count()" #check whether specific parameter is set at least once
        count_ == 0 && continue
        relationship_parameter_value_list =
            py"$mapping.relationship_parameter_value_list(parameter_name=$parameter_name)"
        # Get object_class_name_list from first row in the result, e.g. ["unit", "node"]
        object_class_name_list = nothing
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_class_name_list = [
                String(x) for x in split(relationship_parameter_value["object_class_name_list"], ",")
            ]
            break
        end
        fix_name_ambiguity!(object_class_name_list) #rename entries of this list by appending increasing integer values if entry occures more than one time
        relationship_parameter_value_dict = Dict{String,Any}()
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]" #iterate through list of all values set for this parameter to create a  Dict("obj1,obj2,..." => Dict("json"=>..., "value"=>...), ... )
            object_name_list = relationship_parameter_value["object_name_list"] #"obj1,obj2,..." e.g. "CoalPlant,Electricity,Coal"
            json = try
                JSON.parse(relationship_parameter_value["json"])
            catch LoadError
                nothing
            end
            value = relationship_parameter_value["value"]
            relationship_parameter_value_dict[object_name_list] = Dict{String,Any}(
                "json" => json,
                "value" => as_number(value)
            )
        end
        @suppress_err begin
            @eval begin #create and export convenience function named same is the parameter
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    relationship_parameter_value_dict = $(relationship_parameter_value_dict)
                    object_class_name_list = $(object_class_name_list)
                    if length(kwargs)==0 #if no kwargs are provided a dict of all parameter values is returned
                         d = Dict([String(x) for x in split(key,",")] => v["json"]==nothing?v["value"]:v["json"] for (key, v) in relationship_parameter_value_dict)
                         return d
                    end
                    #create list valid object class names
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
                    result = relationship_parameter_value_dict[object_name_list]
                    result["json"] == nothing && return result["value"]
                    return result["json"][t]
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end

"""
    JuMP_all_out(mapping::PyObject)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the
database given by `mapping`. `mapping` is an instance of `DatabaseMapping`
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
function JuMP_all_out(mapping::PyObject)
    JuMP_object_out(mapping)
    JuMP_relationship_out(mapping)
    JuMP_object_parameter_out(mapping)
    JuMP_relationship_parameter_out(mapping)
end
