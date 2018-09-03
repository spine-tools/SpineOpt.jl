using DataFrames
using Missings
import Base.convert


struct DBObject
    name::String
    id::Int64
    class_id::Int64
end
struct DBObjectClass
    name::String
    id::Int64
end
struct DBRelationshipClass
    name::String
    id::Int64
    object_class_ids::Array{Int64,1}
end
struct DBRelationship
    id::Int64
    class_id::Int64
    object_ids::Array{Int64,1}
end
struct DBParameter
    id::Int64
    class::Union{DBRelationshipClass, DBObjectClass}
    name::String
end
struct RelData
    class::DBRelationshipClass
    data::DataFrame
end


function  convert(::Type{DataFrame}, v::JuMP.JuMPDict{Float64, N} where N)

    var_keys = keys(v)
    first_key = first(var_keys)
    col_types = vcat([typeof(x) for x in first_key], typeof(v[first_key...]))
    num_keys = length(first_key)

    df = DataFrame(col_types, length(v))
    for (i, key) in enumerate(var_keys)
        df[i,end] = v[key...]
        for k in 1:num_keys
            df[i,k] = key[k]
        end
    end
    return df
end

function new_object(db::PyObject, name::String, class_id::Int64)
    result = db[:add_object](name = name, class_id = class_id)
    return DBObject(result[:name], result[:id], result[:class_id])
end

function get_or_add_object_class(db::PyObject, name::String)
    result_class = db[:single_object_class](name = name)[:all]()
    if length(result_class) > 0
        result_class = DBObjectClass(result_class[1][2], result_class[1][1])
    else
        result = db[:add_object_class](name = name)
        result_class = DBObjectClass(result[:name], result[:id])
    end
    return result_class
end

function get_or_add_relationship_class(db::PyObject, name::String, object_class_ids::Array{Int64,1})
    existing_class = db[:relationship_class_list]()[:filter](db[:RelationshipClass][:name][:in_]([name]))[:order_by](db[:RelationshipClass][:dimension])[:all]()
    if length(existing_class) > 0
        class_id = existing_class[1][1]
        object_classes = [o[3] for o in existing_class]
    else
        #create new relationship class
        # getting sql foreign key error when sending integers to python, sending floats seems to work
        result = db[:add_wide_relationship_class](name = name, object_class_id_list = convert.(Float64, object_class_ids))
        class_id = result[1]
    end
    return DBRelationshipClass(name, class_id, object_class_ids)
end

function new_relationship(db::PyObject, name::String, class::DBRelationshipClass, object_ids::Array{Int64,1})
    # getting sql foreign key error when sending integers to python, sending floats seems to work
    object_ids = convert.(Float64, object_ids)
    result = db[:add_wide_relationship](name = name, class_id = class.id, object_id_list = object_ids)
    return DBRelationship(result[1], class.id, object_ids)
end

function get_or_add_parameter(db::PyObject, name::String, class::DBRelationshipClass)
    existing_par = db[:relationship_parameter_list]()[:filter](db[:Parameter][:name][:in_]([name]))[:all]()
    if length(existing_par) > 0
        id = existing_par[1][3]
    else
        par = db[:add_parameter](name = name, relationship_class_id = class.id)
        id = par[:id]
    end
    return DBParameter(id, class, name)
end

function get_or_add_parameter(db::PyObject, name::String, class::DBObjectClass)
    existing_par = db[:object_parameter_list]()[:filter](db[:Parameter][:name][:in_]([name]))[:all]()
    if length(existing_par) > 0
        id = existing_par[1][3]
    else
        par = db[:add_parameter](name = name, object_class_id = class.id)
        id = par[:id]
    end
    return DBParameter(id, class, name)
end

function add_parameter_json(db::PyObject, json::String, parameter::DBParameter, parent::DBRelationship)
    db[:add_parameter_value](parameter_id = parameter.id, relationship_id = parent.id, json = json)
end

function add_parameter_json(db::PyObject, json::String, parameter::DBParameter, parent::DBObject)
    db[:add_parameter_value](parameter_id = parameter.id, object_id = parent.id, json = json)
end

function export_data(db::PyObject, data::DataFrame, class::DBRelationshipClass)
    """Exports relationship json data to a spine database file.

    Arguments:
        `db::PyObject`: reference to DatabaseMapping from SpineDatabaseApi package, database to insert into.
        `data::Dataframe`: Dataframe with 4 columns (:name, :object_ids, :parameter_name ,:json)
            `:name::String`: name of relationship path
            `:object_ids::Array{Int64, 1}`: object ids of relationship
            `:parameter_name::String`: name of parameter
            `:json::String`: json string with parameter value
        `class::DBRelationshipClass`: relationship class of data
    """

    # create new relationships
    unique_object_paths = unique(data[:,[:name, :object_ids]])
    relationships = Dict{String, DBRelationship}()
    for (i, r) in enumerate(eachrow(unique_object_paths))
        rel = new_relationship(db, r[:name], class ,r[:object_ids])
        relationships[r[:name]] = rel
    end
    unique_parameters = unique(data[:,:parameter_name])

    # get parameters
    parameters = Dict{String, DBParameter}()
    for (i, p) in enumerate(unique_parameters)
        parameters[p] = get_or_add_parameter(db, p, class)
    end

    # insert parameters
    for d in eachrow(data)
        relationship = relationships[d[:name]]
        parameter = parameters[d[:parameter_name]]
        add_parameter_json(db, d[:json], parameter, relationship)
    end
end

function JuMP_var_to_spine_format(JuMP_var::JuMP.JuMPDict{JuMP.Variable,N} where N, name::String, result_object::DBObject, result_class::DBObjectClass, object_dict::Dict{String,DBObject}, object_class_dict::Dict{Int64,DBObjectClass})
    """Converts a JuMP variable to a dataframe with spine format and interger ids for objects.
    """
    var_values = getvalue(JuMP_var)
    var_keys = keys(JuMP_var)
    first_key = first(var_keys)

    td = convert(DataFrame, var_values)

    # check how many objects are in the key
    num_objects = 0
    for key in first_key
        if haskey(object_dict, key)
            num_objects = num_objects + 1
        else
            break
        end
    end

    num_var_index = size(td,2)-2-num_objects

    # get object class of object
    object_header = [Symbol(string(object_class_dict[object_dict[k].class_id].name, i)) for (i, k) in enumerate(first_key[1:num_objects])]
    var_header = [Symbol("var$i") for i in 1:num_var_index]
    headers = vcat(object_header, var_header ,[Symbol("time"),Symbol("json")])
    num_indexes = size(td,2) - 1

    names!(td,headers)
    # sort and then split by objects.
    sort!(td,[1:num_indexes;])
    packed_values = by(td, [1:num_objects+num_var_index;]) do df
        DataFrame(json = JSON.json(df[:json]))
    end

    #create a column with array of ids and string with names separated with "_"
    id_col = Array{Array{Int64,1}}(size(packed_values,1))
    name_col = Array{String}(size(packed_values,1))
    for r in 1:size(packed_values,1)
        id_col[r] = vcat(result_object.id, vec([object_dict[p].id for p in Array(packed_values[r,object_header])]))
        name_col[r] = result_object.name*"_"*join(Array(packed_values[r,object_header]),"_")
    end
    packed_values[:name] = name_col
    packed_values[:object_ids] = id_col

    if length(var_header) > 0
        packed_values[:parameter_name] = [name*"_"*join(Array(r[var_header])) for r in eachrow(packed_values)]
    else
        packed_values[:parameter_name] = name
    end

    object_classes = [object_class_dict[object_dict[k].class_id] for k in first_key[1:num_objects]]
    object_classes = vcat(result_class, object_classes)
    rel_name = join([c.name for c in object_classes],"_")

    column_order = vcat(:name, :object_ids, :parameter_name ,:json)

    return packed_values[column_order], rel_name, object_classes
end

function JuMP_variables_to_spine_db(JuMP_vars::Dict{String, JuMP.JuMPDict{JuMP.Variable,N} where N}, dbpath::String, result_name::String)
    """Exports a JuMP variable into a spine database.

    Finds object and relationships using JuMP variables keys and searching the database for exact matches. 
    Creates new relationships and relationship classes if they don't already exists.
    Creates new result object with relationships to keys in JuMP variable

    Arguments:
        `JuMP_vars::Dict{String, JuMP.JuMPDict{JuMP.Variable,N} where N}`: Dict with JuMP variables where the key is the name of the variable inserted into the database.
        `dbpath::String`: path of dbfile to insert into.
        `result_name::String`: name of result object
    """
    mapping = db_api[:DatabaseMapping](dbpath)

    mapping[:new_commit]()
    try

        result_class = get_or_add_object_class(mapping, "result")

        result_object = new_object(mapping, result_name, result_class.id)

        objects = mapping[:object_list]()[:all]()
        object_dict = Dict(i[3]=> DBObject(i[3],i[1],i[2]) for i in objects)
        object_classes = mapping[:object_class_list]()[:all]()
        object_class_dict = Dict(i[1]=> DBObjectClass(i[2],i[1]) for i in object_classes)

        for (var_name, v) in JuMP_vars
            data, rel_name, rel_classes = JuMP_var_to_spine_format(v, var_name, result_object, result_class, object_dict, object_class_dict)

            object_class_ids = [rc.id for rc in rel_classes]

            class = get_or_add_relationship_class(mapping, rel_name, object_class_ids)

            export_data(mapping, data, class)
        end

        mapping[:commit_session]("saved from julia")
        mapping[:session][:close]()
    catch err
        mapping[:rollback_session]()
        mapping[:session][:close]()
        throw(err)
    end


end

function JuMP_variables_to_spine_db(JuMP_vars::JuMP.JuMPDict{JuMP.Variable}, var_name::String, dbpath::String, result_name::String)
    JuMP_vars_dict = Dict(var_name => JuMP_vars)
    JuMP_variables_to_spine_db(JuMP_vars_dict, dbpath, result_name)
end

function JuMP_variables_to_spine_db(JuMP_vars::Array{JuMP.JuMPDict{JuMP.Variable},1}, var_name::Array{String,1}, dbpath::String, result_name::String)
    JuMP_vars_dict = Dict(zip(var_name,JuMP_vars))
    JuMP_variables_to_spine_db(JuMP_vars_dict, dbpath, result_name)
end
