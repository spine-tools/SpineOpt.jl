"""
    JuMP_object(dsn)

A JuMP-friendly julia `Dict` translated from the database specified by `source`.
The database should be in the Spine format. The argument `source`
can either be an `SQLite.DB` or an `ODBC.DSN` object. See
[`JuMP_object(sdo::SpineDataObject)`](@ref) for translation rules.
"""
JuMP_object(source) = JuMP_object(Spine_object(source))

"""
    JuMP_object(sdo::SpineDataObject)

A JuMP-friendly object translated from `sdo`.
A JuMP-friendly object is a Jula `Dict` of `Array`s and `Dict`s, as follows:

 - For each object class in `sdo`
   there is a key-value pair where the key is the class name,
   and the value is an `Array` of object names.

 - For each parameter definition in `sdo`
   there is a key-value pair where the key is the parameter name,
   and the value is another `Dict` of object names and their values.

 - For each relationship class in `sdo`
   there is a key-value pair where the key is the relationship class name,
   and the value is another `Dict` of child and parent object names.

# Example
```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["gen"]
33-element Array{String,1}:
 "gen1"
 "gen2"
...
julia> jfo["pmax"]
Dict{String,Int64} with 33 entries:
  "gen24" => 197
  "gen4"  => 0
  "gen7"  => 400
...
julia> jfo["gen_bus"]
Dict{String,String} with 33 entries:
  "gen24" => "bus21"
  "gen4"  => "bus1"
...
```
"""
function JuMP_object(sdo::SpineDataObject)
    jfo = Dict{String,Any}()
    jfo[".METADATA"] = Dict{String,Array}()
    jfo[".METADATA"]["object_class"] = Array{String,1}()
    jfo[".METADATA"]["relationship_class"] = Array{String,1}()
    jfo[".METADATA"]["parameter"] = Array{String,1}()
    for i=1:size(sdo.object_class, 1)
        object_class_id = sdo.object_class[i, :id]
        object_class_name = sdo.object_class[i, :name]
        jfo[object_class_name] = @from object in sdo.object begin
            @where object.class_id == object_class_id
            @select get(object.name)
            @collect
        end
        push!(jfo[".METADATA"]["object_class"], object_class_name)
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
            @collect Dict{Any,Any}
        end
        parent_to_child = @from relationship in relationship_df begin
            @group relationship by relationship.parent_object_name into group
            @let group_arr = [get(x) for x in group..child_object_name]
            @select get(group.key) => all_or_one(group_arr)
            @collect Dict{Any,Any}
        end
        jfo[relationship_class_name] = merge(child_to_parent, parent_to_child)
        push!(jfo[".METADATA"]["relationship_class"], relationship_class_name)
    end
    for i=1:size(sdo.parameter,1)
        parameter_id = sdo.parameter[i, :id]
        parameter_name = sdo.parameter[i, :name]
        data_type = sdo.parameter[i, :data_type]
        jfo[parameter_name] = @from parameter in sdo.parameter_value begin
            @where parameter.parameter_id == parameter_id
            @join object in sdo.object on parameter.object_id equals object.id
            @select get(object.name) => get(parameter.value)
            @collect Dict{Any,get(spine2julia, data_type, Any)}
        end
        push!(jfo[".METADATA"]["parameter"], parameter_name)
    end
    jfo
end

function all_or_one(arr::Array)
    length(arr) == 1 && return arr[]
    arr
end


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
        #push!(sdo.object_class, [object_class_id, object_class_name, display_order])
        # Note: this below assumes all objects have different name, regardless of their class
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
        for (parent_object_name, child_object_name) in jfo[relationship_class_name]
            isa(child_object_name, Array) && continue
            parent_object = filter(x -> x[:class_id] == parent_object_class_id, sdo.object)
            parent_object_id = findfirst(parent_object[:name], parent_object_name)
            parent_object_id == 0 && continue
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
