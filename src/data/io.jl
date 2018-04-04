"""
    read_Spine_object(dsn)

Build a Spine Data Object from a Database specified by a Data Source Name
"""
function read_Spine_object(dsn::ODBC.DSN; database::String = "")
    !isempty(database) && ODBC.execute!(dsn, string("USE ", database))
    data = Array{DataFrame, 1}()
    tables = [
        "object_classes"
        "objects"
        "relationship_classes"
        "relationships"
        "parameter_definitions"
        "parameters"
    ]
    for table in tables
        qry = string("SELECT * FROM ", compose_table_name(dsn, table))
        push!(data, ODBC.query(dsn, qry))
    end
    SpineDataObject(data...)
end

read_Spine_object(dsn_str::AbstractString; kwargs...) = read_Spine_object(ODBC.DSN(dsn_str); kwargs...)

"""
    build_JuMP_object(dsn)

Build a JuMP Friendly Object from a Database specified by a Data Source Name
"""
function build_JuMP_object(dsn::ODBC.DSN; database::String = "")
    !isempty(database) && ODBC.execute!(dsn, string("USE ", database))
    jfo = Dict{String,Any}()
    table = compose_table_name(dsn, "object_classes")
    qry = string("SELECT Object_class FROM ", table)
    for obj_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "objects")
        qry = string("SELECT Object FROM ", table,
            " WHERE Object_class = '", obj_class, "'")
        jfo[obj_class] = ODBC.query(dsn, qry, ArraySink)
    end
    table = compose_table_name(dsn, "relationship_classes")
    qry = string("SELECT Relationship_class FROM ", table)
    for rel_class in ODBC.query(dsn, qry, ArraySink)
        table = compose_table_name(dsn, "relationships")
        qry = string("SELECT Child_object, Parent_object FROM ", table,
            " WHERE Relationship_class = '", rel_class, "'")
        jfo[rel_class] = ODBC.query(dsn, qry, DictSink)
    end
    table = compose_table_name(dsn, "parameter_definitions")
    qry = string("SELECT Parameter, DataType FROM ", table)
    for (par, datatype) in ODBC.query(dsn, qry, DictSink)
        table = compose_table_name(dsn, "parameters")
        qry = string("SELECT Child, Value FROM ", table,
            " WHERE Parameter = '", par, "'")
        jfo[par] = ODBC.query(dsn, qry, DictSink, datatype)
    end
    jfo
end

build_JuMP_object(dsn_str::AbstractString; kwargs...) = build_JuMP_object(ODBC.DSN(dsn_str); kwargs...)

function build_JuMP_object(sdo::SDO)
    jfo = Dict{String,Any}()
    for obj_class in sdo.object_classes[:Object_class]
        jfo[obj_class] = @from k in sdo.objects begin
            @where k.Object_class == obj_class
            @select k.Object
            @collect
        end
    end
    for rel_class in sdo.relationship_classes[:Relationship_class]
        jfo[rel_class] = @from k in sdo.relationships begin
            @where k.Relationship_class == rel_class
            @select k.Child_object => k.Parent_object
            @collect Dict{String,String}
        end
    end
    for i=1:size(sdo.parameter_definitions,1)
        par = sdo.parameter_definitions[i, :Parameter]
        datatype = sdo.parameter_definitions[i, :DataType]
        jfo[par] = @from k in sdo.parameters begin
            @where k.Parameter == par
            @select k.Child => get(k.Value)
            @collect Dict{String,spine2julia[datatype]}
        end
    end
    jfo
end
