"""
    JuMP_object(source)

A JuMP-friendly object from `source`. The argument `source`
is anything that can be converted to a `SpineDataObject` using `SpineData.jl`. See details of conversion in
[`JuMP_object(sdo::SpineDataObject)`](@ref).
"""
function JuMP_object(source, update_all_datatypes=true, JuMP_all_out=true)
    sdo = Spine_object(source)
    update_all_datatypes && update_all_datatypes!(sdo)
    JuMP_object(sdo, JuMP_all_out)
end

"""
    JuMP_object(sdo::SpineDataObject, JuMP_all_out=true)

A JuMP-friendly object from `sdo`.
A JuMP-friendly object is simply a Julia `Dict`.
The following 'translation' rules apply:

 - An object class in `sdo` is a pair `object_class_name=>Array of object_name`.

 - A parameter in `sdo` is a pair `parameter_name=>Dict of object_name=>parameter_value`

 - A relationship class in `sdo` is a pair `relationship_class_name=>Dict of parent_object_name=>(Array of) child_object_name`.

# Example
```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["unit"]
33-element Array{String,1}:
 "unit1"
 "unit2"
...
julia> jfo["pmax"]
Dict{String,Int64} with 33 entries:
  "unit24" => 197
  "unit4"  => 0
  "unit7"  => 400
...
julia> jfo["unit_node"]
Dict{String,String} with 33 entries:
  "unit24" => "node21"
  "unit4"  => "node1"
  ...
  "node1" => ["unit4", "unit5", "unit7"]
...
```
"""
function JuMP_object(sdo::SpineDataObject, JuMP_all_out=true)
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
        JuMP_all_out || continue
        @suppress_err begin
            @eval begin
                $(Symbol(object_class_name))() = $(jfo[object_class_name])
                export $(Symbol(object_class_name))
            end
        end
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
        child_to_parent = @from relationship in relationship_df begin
            @group relationship by relationship.child_object_name into group
            @let group_arr = [get(x) for x in group..parent_object_name]
            @select get(group.key) => all_or_one(group_arr)
            @collect Dict{String,Any}
        end
        parent_to_child = @from relationship in relationship_df begin
            @group relationship by relationship.parent_object_name into group
            @let group_arr = [get(x) for x in group..child_object_name]
            @select get(group.key) => all_or_one(group_arr)
            @collect Dict{String,Any}
        end
        jfo[relationship_class_name] = merge(child_to_parent, parent_to_child)
        add_relationship_class_metadata!(jfo, relationship_class_name)
        JuMP_all_out || continue
        @eval begin
            function $(Symbol(relationship_class_name))(x::String)
                relationship_class_name = $(jfo[relationship_class_name])
                try
                    relationship_class_name[x]
                catch KeyError
                    error($relationship_class_name, " is not defined for object ", x)
                end
            end
            export $(Symbol(relationship_class_name))
        end
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
            @let json_value = isnull(parameter.json)?missing:JSON.parse(get(parameter.json))
            @select get(object.name) => json_value
            @collect Dict{String,Any}
        end
        # NOTE: this prioritizes json over value if json not missing
        jfo[parameter_name] = Dict{String,Any}(
            k => ismissing(json[k])?v:json[k] for (k,v) in value
        )
        add_parameter_metadata!(jfo, parameter_name)
        JuMP_all_out || continue
        @eval begin
            function $(Symbol(parameter_name))(x::String, t::Int64=1)
                if t > 1
                    json = $(json)
                    return json[x][t]
                end
                value = $(value)
                value[x]
            end
            export $(Symbol(parameter_name))
        end
    end
    logging()
    jfo
end

function all_or_one(arr::Array{T,1}) where T
    length(arr) == 1 && return arr[]
    arr
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

A `SpineDataObject` from `jfo`. See details of conversion in
[`JuMP_object(sdo::SpineDataObject)`](@ref).
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

#=
Translation rules are
outlined in the table below:

<table>
  <tr>
    <th rowspan=2>Spine object</th>
    <th colspan=2>JuMP object</th>
  </tr>
  <tr>
    <td><i>Key</i></td>
    <td><i>Value</i></td>
  </tr>
  <tr>
    <td>objects</td>
    <td>Object_class</td>
    <td>Array(Object, ...)</td>
  </tr>
  <tr>
    <td>relationships</td>
    <td>Relationship_class</td>
    <td>Dict(Child_object => Parent_object, ...)</td>
  </tr>
  <tr>
    <td>parameters</td>
    <td>Parameter</td>
    <td>Dict(Child => Value, ...)</td>
  </tr>
</table>
=#
