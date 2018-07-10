"""
    JuMP_all_out(source, update_all_datatypes=true)

Generate and export convenience functions
named after each object class, relationship class, and parameter in `source`,
providing compact access to its contents, where `source`
is anything convertible to a `SpineDataObject` by the `SpineData.jl` package.
See also: [`JuMP_all_out(sdo::SpineDataObject, update_all_datatypes=true)`](@ref) for details
about the generated convenience functions.

If `update_all_datatypes` is `true`, then the method tries to find out the julia `Type` that best fits
all values for every parameter in `sdo`, and converts all values to that `Type`. (See `SpineData.update_all_datatypes!`.)
"""
function JuMP_all_out(source, update_all_datatypes=true)
    sdo = Spine_object(source)
    JuMP_all_out(sdo, update_all_datatypes)
end

"""
    JuMP_all_out(sdo::SpineDataObject, update_all_datatypes=true)

Generate and export convenience functions
named after each object class, relationship class, and parameter in `sdo`,
providing compact access to its contents.
These functions are intended to be called in JuMP programs, as follows:

  - **object class**: call `x()` to get the set of names of objects of the class named `"x"`.
  - **relationship class**: call `y("k")` to get the set of names of objects
    related to the object named `"k"`, by a relationship of class named `"y"`,
    or an empty set if no such relationship exists.
  - **parameter**: call `z("k", t)` to get the value of the parameter named `"z"` for the object
    named `"k"`, or `Nullable()` if the parameter is not defined.
    If this value is an array in the Spine object, then `z("k", t)` returns position `t` in that array.

If `update_all_datatypes` is `true`, then the method tries to find the julia `Type` that best fits
all values for every parameter in `sdo`, and converts all values to that `Type`.
(See `SpineData.update_all_datatypes!`.)

# Example
```julia
julia> JuMP_all_out(sdo)
julia> commodity()
3-element Array{String,1}:
 "coal"
 "gas"
...
julia> unit_node("Leuven")
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> conversion_cost("gas_import")
12
julia> demand("Leuven", 17)
700
```
"""
function JuMP_all_out(sdo::SpineDataObject, update_all_datatypes=true)
    jfo = JuMP_object(sdo, update_all_datatypes)
    for object_class_name in jfo[".METADATA"]["object_class"]
        object_names = jfo[object_class_name]
        @suppress_err begin
            @eval begin
                $(Symbol(object_class_name))() = $(object_names)
                export $(Symbol(object_class_name))
            end
        end
    end
    for relationship_class_name in jfo[".METADATA"]["relationship_class"]
        related_object_names = jfo[relationship_class_name]
        @suppress_err begin
            @eval begin
                function $(Symbol(relationship_class_name))(x::String)
                    relationship_class_name = $(related_object_names)
                    get(relationship_class_name, x, [])
                end
                export $(Symbol(relationship_class_name))
            end
        end
    end
    for parameter_name in jfo[".METADATA"]["parameter"]
        value = jfo[parameter_name]
        @suppress_err begin
            @eval begin
                function $(Symbol(parameter_name))(x::String, t::Int64=1)
                    value = $(value)
                    if haskey(value, x)
                        if isa(value[x], Array)
                            if t in linearindices(value[x])
                                return value[x][t]
                            end
                        end
                        return value[x]
                    end
                    Nullable()
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end

"""
    JuMP_object(sdo::SpineDataObject, update_all_datatypes=true)

A julia `Dict` providing
custom maps of the contents of `sdo`. In what follows, `jfo` designs this `Dict`.
The specific roles of these maps are described below:

  - **object class map**: `object_class_name::String` ⟶ `object_names::Array{String,1}`.
    This map assigns an object class's name to a list of names of objects of that class.
    You can refer to the set of objects of the class named `"x"` as `jfo["x"]`.
  - **relationship class map**: `relationship_class_name::String` ⟶ `object_name::String` ⟶
    `related_object_names::Array{String,1}`.
    This multilevel map assigns, for each relationship class name, a map from an object's name
    to a list of related
    object names. You can use this map to get the set of names of objects related to the object called `"k"`
    by a relationship of the class named `"y"` as
    `jfo["y"]["k"]`.
  - **parameter map**: `parameter_name::String` ⟶ `object_name::String` ⟶ `parameter_value::T`.
    This multilevel map assigns, for each parameter name, a map from an object's name
    to the value of the parameter for that object.
    You can use this map to access the value of the parameter called `"z"` for the object called `"k"` as
    `jfo["z"]["k"]`. If the value for this parameter in `sdo` is an array, you can access position `t` in that array
    as `jfo["z"]["k"][t]`

# Example
```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["unit"]
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> jfo["unit_node"]
Dict{String,String} with 5 entries:
  "coal_fired_power_plant" => ["Leuven"]
  "coal_import"  => ["Leuven"]
  ...
  "Leuven" => ["coal_fired_power_plant", "coal_import", ...]
...
julia> jfo["conversion_cost"]
Dict{String,Int64} with 4 entries:
  "gas_import" => 12
  "coal_fired_power_plant"  => 0
...
```
"""
function JuMP_object(sdo::SpineDataObject, update_all_datatypes=true)
    update_all_datatypes && update_all_datatypes!(sdo)
    jfo = Dict{String,Any}()
    init_metadata!(jfo)
    for i=1:size(sdo.object_class, 1)
        object_class_id = sdo.object_class[i, :id]
        object_class_name = sdo.object_class[i, :name]
        jfo[object_class_name] = @from object in sdo.object begin
            @where object.class_id == object_class_id
            @select get(object.name)
            @collect
        end
        add_object_class_metadata!(jfo, object_class_name)
    end
    for i=1:size(sdo.relationship_class, 1)
        relationship_class_id = sdo.relationship_class[i, :id]
        relationship_class_name = sdo.relationship_class[i, :name]
        relationship_df = @from relationship in sdo.relationship begin
            @where relationship.class_id == relationship_class_id
            @join child_object in sdo.object on relationship.child_object_id equals child_object.id
            @join parent_object in sdo.object on relationship.parent_object_id equals parent_object.id
            @select {child_object_name=child_object.name, parent_object_name=parent_object.name}
            @collect DataFrame
        end
        child_to_parent_object_names = @from relationship in relationship_df begin
            @group relationship by relationship.child_object_name into group
            @let group_arr = [get(x) for x in group..parent_object_name]
            @select get(group.key) => group_arr
            @collect Dict{String,Any}
        end
        parent_to_child_object_names = @from relationship in relationship_df begin
            @group relationship by relationship.parent_object_name into group
            @let group_arr = [get(x) for x in group..child_object_name]
            @select get(group.key) => group_arr
            @collect Dict{String,Any}
        end
        jfo[relationship_class_name] = merge(child_to_parent_object_names, parent_to_child_object_names)
        add_relationship_class_metadata!(jfo, relationship_class_name)
    end
    for i=1:size(sdo.parameter,1)
        parameter_id = sdo.parameter[i, :id]
        parameter_name = sdo.parameter[i, :name]
        data_type = sdo.parameter[i, :data_type]
        value = @from parameter in sdo.parameter_value begin
            @where parameter.parameter_id == parameter_id
            @join object in sdo.object on parameter.object_id equals object.id
            @select get(object.name) => get(parameter.value)
            @collect Dict{String,get(spine2julia, data_type, Any)}
        end
        json = @from parameter in sdo.parameter_value begin
            @where parameter.parameter_id == parameter_id
            @join object in sdo.object on parameter.object_id equals object.id
            @let json_value = isna(parameter.json)?Nullable():JSON.parse(get(parameter.json))
            @select get(object.name) => json_value
            @collect Dict{String,Any}
        end
        # NOTE: this prioritizes json over value if json is not missing
        jfo[parameter_name] = Dict{String,Any}(
            k => isnull(json[k])?v:json[k] for (k,v) in value
        )
        add_parameter_metadata!(jfo, parameter_name)
    end
    jfo
end

# metadata convenience functions
function init_metadata!(jfo::Dict)
    jfo[".METADATA"] = Dict{String,Array}()
    jfo[".METADATA"]["object_class"] = Array{String,1}()
    jfo[".METADATA"]["relationship_class"] = Array{String,1}()
    jfo[".METADATA"]["parameter"] = Array{String,1}()
end

function add_object_class_metadata!(jfo::Dict, names...)
    for name in names
        push!(jfo[".METADATA"]["object_class"], name)
    end
end

function add_relationship_class_metadata!(jfo::Dict, names...)
    for name in names
        push!(jfo[".METADATA"]["relationship_class"], name)
    end
end

function add_parameter_metadata!(jfo::Dict, names...)
    for name in names
        push!(jfo[".METADATA"]["parameter"], name)
    end
end

"""
    SpineData.Spine_object(jfo::Dict)

A `SpineDataObject` from `jfo`.

See also [`JuMP_object(sdo::SpineDataObject, update_all_datatypes=true)`](@ref).
"""
function SpineData.Spine_object(jfo::Dict)
    sdo = MinimalSDO()
    metadata = jfo[".METADATA"]
    object_class = metadata["object_class"]
    object_id = 1
    for (object_class_id, object_class_name) in enumerate(object_class)
        display_order = object_class_id
        push!(sdo.object_class, [object_class_id, object_class_name, display_order])
        for object_name in jfo[object_class_name]
            push!(sdo.object, [object_id, object_class_id, object_name])
            object_id += 1
        end
    end
    relationship_class = metadata["relationship_class"]
    relationship_id = 1
    for (relationship_class_id, relationship_class_name) in enumerate(relationship_class)
        # Add relationship class
        # Infer parent and child object class from the objects of the first relationship
        # This is possible since object names are UNIQUE
        parent_object_class_id = nothing
        child_object_class_id = nothing
        for (parent_object_name, child_object_name) in jfo[relationship_class_name]
            isa(child_object_name, Array) && continue
            parent_object_id = findfirst(sdo.object[:name], parent_object_name)
            parent_object_class_id = sdo.object[parent_object_id, :class_id]
            child_object_id = findfirst(sdo.object[:name], child_object_name)
            child_object_class_id = sdo.object[child_object_id, :class_id]
            push!(sdo.relationship_class, [
                    relationship_class_id,
                    relationship_class_name,
                    parent_object_class_id,
                    child_object_class_id
                ]
            )
            break
        end
        # Add relationship
        for (parent_object_name, child_object_name) in jfo[relationship_class_name]
            isa(child_object_name, Array) && continue
            @show relationship_class_name
            parent_object = filter(x -> x[:class_id] == parent_object_class_id, sdo.object)
            i = findfirst(parent_object[:name], parent_object_name)
            i == 0 && continue
            parent_object_id = parent_object[i, :id]
            child_object_id = findfirst(sdo.object[:name], child_object_name)
            relationship_name = string(parent_object_name, "_", child_object_name)
            push!(sdo.relationship, [
                    relationship_id,
                    relationship_class_id,
                    relationship_name,
                    parent_object_id,
                    child_object_id
                ]
            )
            relationship_id += 1
        end
    end
    parameter = metadata["parameter"]
    parameter_value_id = 1
    for (parameter_id, parameter_name) in enumerate(parameter)
        # Add parameter
        # Infer object class from the object of the first parameter
        # This is possible since object names are UNIQUE
        for (object_name, value) in jfo[parameter_name]
            object_id = findfirst(sdo.object[:name], object_name)
            object_class_id = sdo.object[object_id, :class_id]
            data_type = julia2spine(typeof(value))
            unit = missing
            push!(sdo.parameter, [
                    parameter_id,
                    parameter_name,
                    data_type,
                    object_class_id,
                    unit
                ]
            )
            break
        end
        # Add parameter value
        for (object_name, value) in jfo[parameter_name]
            object_id = findfirst(sdo.object[:name], object_name)
            push!(sdo.parameter_value, [parameter_value_id, parameter_id, object_id, value])
            parameter_value_id += 1
        end
    end
    sdo
end
