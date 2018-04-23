function JuMP_object(dsn::ODBC.DSN; database::String = "")
    !isempty(database) && ODBC.execute!(dsn, string("USE ", database))
    jfo = Dict{String,Any}()
    table = compose_table_name(dsn, "object_class")
    qry = string("SELECT name FROM ", table)
    for obj_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "object")
        qry = string("SELECT name FROM ", table,
            " WHERE class_name = '", obj_class, "'")
        jfo[obj_class] = ODBC.query(dsn, qry, ArraySink)
    end
    table = compose_table_name(dsn, "relationship_class")
    qry = string("SELECT name FROM ", table)
    for rel_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "relationship")
        qry = string("SELECT child_object_name, parent_object_name FROM ", table,
            " WHERE class_name = '", rel_class, "'")
        jfo[rel_class] = ODBC.query(dsn, qry, DictSink)
    end
    table = compose_table_name(dsn, "parameter_definition")
    qry = string("SELECT name, data_type FROM ", table)
    for (par, datatype) in ODBC.query(dsn, qry, DictSink)
        table = compose_table_name(dsn, "parameter")
        qry = string("SELECT object_name, value FROM ", table,
            " WHERE name = '", par, "'")
        jfo[par] = ODBC.query(dsn, qry, DictSink, datatype)
    end
    jfo
end

"""
    JuMP_object(dsn)

A JuMP-friendly julia `Dict` translated from the database specified by `dsn`.
The database should be in the Spine format. The argument `dsn`
can either be an `AbstractString` or an `ODBC.DSN` object. See
[`JuMP_object(sdo::SpineDataObject)`](@ref) for translation rules.
"""
JuMP_object(dsn_str::AbstractString; kwargs...) = JuMP_object(ODBC.DSN(dsn_str); kwargs...)

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
    for object_class_name in sdo.object_class[:name]
        jfo[object_class_name] = @from object in sdo.object begin
            @where object.class_name == object_class_name
            @select get(object.name)
            @collect
        end
    end
    for relationship_class_name in sdo.relationship_class[:name]
        jfo[relationship_class_name] = @from relationship in sdo.relationship begin
            @where relationship.class_name == relationship_class_name
            @select get(relationship.child_object_name) => get(relationship.parent_object_name)
            @collect Dict{Any,Any}
        end
    end
    for i=1:size(sdo.parameter_definition,1)
        parameter_name = sdo.parameter_definition[i, :name]
        datatype = sdo.parameter_definition[i, :data_type]
        jfo[parameter_name] = @from parameter in sdo.parameter begin
            @where parameter.name == parameter_name
            @select get(parameter.object_name) => get(parameter.value)
            @collect Dict{Any,spine2julia[datatype]}
        end
    end
    jfo
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
