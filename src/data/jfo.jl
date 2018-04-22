function JuMP_object(dsn::ODBC.DSN; database::String = "")
    !isempty(database) && ODBC.execute!(dsn, string("USE ", database))
    jfo = Dict{String,Any}()
    table = compose_table_name(dsn, "object_classes")
    qry = string("SELECT Object_class FROM ", table)
    for obj_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "objects")
        qry = string("SELECT Object FROM ", table,
            " WHERE object_class_id = '", obj_class, "'")
        jfo[obj_class] = ODBC.query(dsn, qry, ArraySink)
    end
    table = compose_table_name(dsn, "relationship_classes")
    qry = string("SELECT relationship_class_id FROM ", table)
    for rel_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "relationships")
        qry = string("SELECT child_object_id, parent_object_id FROM ", table,
            " WHERE relationship_class_id = '", rel_class, "'")
        jfo[rel_class] = ODBC.query(dsn, qry, DictSink)
    end
    table = compose_table_name(dsn, "parameter_definition")
    qry = string("SELECT parameter_id, data_type FROM ", table)
    for (par, datatype) in ODBC.query(dsn, qry, DictSink)
        table = compose_table_name(dsn, "parameters")
        qry = string("SELECT entity_id, parameter_value FROM ", table,
            " WHERE parameter_id = '", par, "'")
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
   there is a key-value pair where the key is the class name (i.e. `Object_class`),
   and the value is an `Array` of object names (i.e. `Object`).

 - For each parameter definition in `sdo`
   there is a key-value pair where the key is the parameter name (i.e. `Parameter`),
   and the value is another `Dict` of child names and their values (i.e. `Child => Value`).

 - For each relationship class in `sdo`
   there is a key-value pair where the key is the relationship class name (i.e. `Relationship_class`),
   and the value is another `Dict` of child names and parent names (i.e. `Child_object => Parent_object`).

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
    for obj_class in sdo.object_classes[:object_class_id]
        jfo[obj_class] = @from k in sdo.objects begin
            @where k.object_class_id == obj_class
            @select get(k.Object)
            @collect
        end
    end
    for rel_class in sdo.relationship_classes[:relationship_class_id]
        jfo[rel_class] = @from k in sdo.relationships begin
            @where k.relationship_class_id == rel_class
            @select get(k.child_object_id) => get(k.parent_object_id)
            @collect Dict{Any,Any}
        end
    end
    for i=1:size(sdo.parameter_definition,1)
        par = sdo.parameter_definition[i, :parameter_id]
        datatype = sdo.parameter_definition[i, :data_type]
        jfo[par] = @from k in sdo.parameters begin
            @where k.parameter == par
            @select get(k.entity_id) => get(k.parameter_value)
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
