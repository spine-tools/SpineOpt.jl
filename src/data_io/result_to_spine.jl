# TODO: remove whitespace inside function bodies

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

"""Converts a JuMPDict variable to a dataframe with value of JuMPDict as last column
"""
function convert_to_dataframe(::Type{DataFrame}, v::JuMP.JuMPDict{Float64, N} where N)
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

function new_object(db_map::PyObject, name::String, class_id::Int64)
    result = py"$db_map.add_object(name = $name, class_id = $class_id)"
    #result = db_map[:add_object](name = name, class_id = class_id)
    return DBObject(result[:name], result[:id], result[:class_id])
end

# NOTE: all these `get_or_add` seem like they could be in `DatabaseMapping`?
function get_or_add_object_class(db_map::PyObject, name::String)
    result_class = py"[x._asdict() for x in $db_map.single_object_class(name = $name).all()]"
    #result_class = db_map[:single_object_class](name = name)[:all]()
    if length(result_class) > 0
        result_class = DBObjectClass(result_class[1]["name"], result_class[1]["id"])
    else
        result = py"$db_map.add_object_class(name = $name)"
        #result = db_map[:add_object_class](name = name)
        result_class = DBObjectClass(result[:name], result[:id])
    end
    return result_class
end

function get_or_add_relationship_class(db_map::PyObject, name::String, object_class_ids::Array{Int64,1})
    # TODO: this line seems too long.
    # Maybe create another method in `DatabaseMapping` that does this?
    existing_class = py"[x._asdict() for x in $db_map.relationship_class_list().filter($db_map.RelationshipClass.name == $name).order_by($db_map.RelationshipClass.dimension).all()]"
    #existing_class = db_map[:relationship_class_list]()[:filter](db_map[:RelationshipClass][:name][:in_]([name]))[:order_by](db_map[:RelationshipClass][:dimension])[:all]()
    if length(existing_class) > 0
        class_id = existing_class[1]["id"]
        object_classes = [o["object_class_id"] for o in existing_class]
    else
        # Create new relationship class
        # FIXME: Getting sql foreign key error when sending integers to python, sending floats seems to work
        float_ids = convert.(Float64, object_class_ids)
        result = py"$db_map.add_wide_relationship_class(name = $name, object_class_id_list = $float_ids)._asdict()"
        #result = db_map[:add_wide_relationship_class](name = name, object_class_id_list = convert.(Float64, object_class_ids))
        class_id = result["id"]
    end
    return DBRelationshipClass(name, class_id, object_class_ids)
end

function new_relationship(db_map::PyObject, name::String, class::DBRelationshipClass, object_ids::Array{Int64,1})
    # FIXME: Getting sql foreign key error when sending integers to python, sending floats seems to work
    object_ids = convert.(Float64, object_ids)
    result = py"$db_map.add_wide_relationship(name = $name, class_id = $class.id, object_id_list = $object_ids)._asdict()"
    #result = db_map[:add_wide_relationship](name = name, class_id = class.id, object_id_list = object_ids)
    return DBRelationship(result["id"], class.id, object_ids)
end

function get_or_add_parameter(db_map::PyObject, name::String, class::DBRelationshipClass)
    existing_par = py"[x._asdict() for x in $db_map.relationship_parameter_list().filter($db_map.Parameter.name == $name).all()]"
    #existing_par = db_map[:relationship_parameter_list]()[:filter](db_map[:Parameter][:name][:in_]([name]))[:all]()
    if length(existing_par) > 0
        id = existing_par[1]["parameter_id"]
    else
        par = py"$db_map.add_parameter(name = $name, relationship_class_id = $class.id)"
        #par = db_map[:add_parameter](name = name, relationship_class_id = class.id)
        id = par[:id]
    end
    return DBParameter(id, class, name)
end

function get_or_add_parameter(db_map::PyObject, name::String, class::DBObjectClass)
    existing_par = py"[x._asdict() for x in $db_map.object_parameter_list().filter($db_map.Parameter.name == $name).all()]"
    #existing_par = db_map[:object_parameter_list]()[:filter](db_map[:Parameter][:name][:in_]([name]))[:all]()
    if length(existing_par) > 0
        id = existing_par[1]["id"]
    else
        par = py"$db_map.add_parameter(name = $name, relationship_class_id = $class.id)"
        #par = db_map[:add_parameter](name = name, object_class_id = class.id)
        id = par[:id]
    end
    return DBParameter(id, class, name)
end

function add_parameter_json(db_map::PyObject, json::String, parameter::DBParameter, parent::DBRelationship)
    py"$db_map.add_parameter_value(parameter_id = $parameter.id, relationship_id = $parent.id, json = $json)"
    #db_map[:add_parameter_value](parameter_id = parameter.id, relationship_id = parent.id, json = json)
end

function add_parameter_json(db_map::PyObject, json::String, parameter::DBParameter, parent::DBObject)
    py"$db_map.add_parameter_value(parameter_id = $parameter.id, object_id = $parent.id, json = $json)"
    #db_map[:add_parameter_value](parameter_id = parameter.id, object_id = parent.id, json = json)
end

"""Exports relationship json data to a spine database file.

    Arguments:
    `db_map::PyObject`: reference to DatabaseMapping from SpineDatabaseApi package, database to insert into.
    `data::Dataframe`: Dataframe with 4 columns (:name, :object_ids, :parameter_name ,:json)
        `:name::String`: name of relationship path
        `:object_ids::Array{Int64, 1}`: object ids of relationship
        `:parameter_name::String`: name of parameter
        `:json::String`: json string with parameter value
    `class::DBRelationshipClass`: relationship class of data
"""
function export_data(db_map::PyObject, data::DataFrame, class::DBRelationshipClass)
    # Create new relationships
    unique_object_paths = unique(data[:,[:name, :object_ids]])
    relationships = Dict{String, DBRelationship}()
    for (i, r) in enumerate(eachrow(unique_object_paths))
        rel = new_relationship(db_map, r[:name], class ,r[:object_ids])
        relationships[r[:name]] = rel
    end
    unique_parameters = unique(data[:,:parameter_name])

    # Get parameters
    parameters = Dict{String, DBParameter}()
    for (i, p) in enumerate(unique_parameters)
        parameters[p] = get_or_add_parameter(db_map, p, class)
    end

    # Insert parameters
    for d in eachrow(data)
        relationship = relationships[d[:name]]
        parameter = parameters[d[:parameter_name]]
        add_parameter_json(db_map, d[:json], parameter, relationship)
    end
end

"""Converts a JuMP variable to a dataframe with spine format and interger ids for objects.
"""
function JuMP_var_to_spine_format(
        JuMP_var::JuMP.JuMPDict{JuMP.Variable,N} where N,
        name::String,
        result_object::DBObject,
        result_class::DBObjectClass,
        object_dict::Dict{String,DBObject},
        object_class_dict::Dict{Int64,DBObjectClass}
    )

    var_values = getvalue(JuMP_var)
    var_keys = keys(JuMP_var)
    first_key = first(var_keys)
    var_dataframe = convert_to_dataframe(DataFrame, var_values)

    # check how many objects are in the key
    num_objects = 0
    for key in first_key
        if haskey(object_dict, key)
            num_objects = num_objects + 1
        else
            break
        end
    end

    # find number of indexes(columns) that was not found as an object in database
    num_var_index = size(var_dataframe, 2) - 2 - num_objects

    # Get object class of object
    object_header = [Symbol(string(object_class_dict[object_dict[k].class_id].name, i)) for (i, k) in enumerate(first_key[1:num_objects])]
    var_header = [Symbol("var$i") for i in 1:num_var_index]
    headers = vcat(object_header, var_header ,[Symbol("time"),Symbol("json")])
    num_indexes = size(var_dataframe,2) - 1

    names!(var_dataframe,headers)
    # Sort and then split by objects.
    sort!(var_dataframe,[1:num_indexes;])
    packed_values = by(var_dataframe, [1:num_objects+num_var_index;]) do df
        DataFrame(json = JSON.json(df[:json]))
    end

    # Create a column with array of ids and string with names separated with "_"
    id_col = Array{Array{Int64,1}}(size(packed_values,1))
    name_col = Array{String}(size(packed_values,1))
    for r in 1:size(packed_values,1)
        id_col[r] = vcat(result_object.id, vec([object_dict[p].id for p in Array(packed_values[r,object_header])]))
        name_col[r] = result_object.name*"_"*join(Array(packed_values[r,object_header]),"_")
    end
    packed_values[:name] = name_col
    packed_values[:object_ids] = id_col

    # join parameter name with columns that are not found in the database
    if length(var_header) > 0
        packed_values[:parameter_name] = [name*"_"*join(Array(r[var_header])) for r in eachrow(packed_values)]
    else
        packed_values[:parameter_name] = name
    end

    # find object class ids
    object_classes = [object_class_dict[object_dict[k].class_id] for k in first_key[1:num_objects]]
    object_classes = vcat(result_class, object_classes)
    rel_name = join([c.name for c in object_classes],"_")

    # columns to keep
    column_order = vcat(:name, :object_ids, :parameter_name ,:json)
    return packed_values[column_order], rel_name, object_classes
end

"""Exports a JuMP variable into a spine database.

Finds object and relationships using JuMP variables keys and searching the database for exact matches.
Creates new relationships and relationship classes if they don't already exists.
Creates new result object with relationships to keys in JuMP variable

Arguments:
    `JuMP_vars::Dict{String, JuMP.JuMPDict{JuMP.Variable,N} where N}`: Dict with JuMP variables where the key is the name of the variable inserted into the database.
    `db_url::String`: path of dbfile to insert into.
    `result_name::String`: name of result object
"""
function JuMP_variables_to_spine_db(JuMP_vars::Dict{String, JuMP.JuMPDict{JuMP.Variable,N} where N}, db_url::String, result_name::String)
    # start database connection and add a new commit
    db_map = db_api[:DatabaseMapping](db_url)
    db_map[:new_commit]()
    try
        result_class = get_or_add_object_class(db_map, "result")
        result_object = new_object(db_map, result_name, result_class.id)

        # get objects and object classes for name too id lookup
        objects = db_map[:object_list]()[:all]()
        object_dict = Dict(i[3]=> DBObject(i[3],i[1],i[2]) for i in objects)
        object_classes = db_map[:object_class_list]()[:all]()
        object_class_dict = Dict(i[1]=> DBObjectClass(i[2],i[1]) for i in object_classes)

        # insert each variable into spine database.
        for (var_name, v) in JuMP_vars
            data, rel_name, rel_classes = JuMP_var_to_spine_format(v, var_name, result_object, result_class, object_dict, object_class_dict)
            object_class_ids = [rc.id for rc in rel_classes]
            class = get_or_add_relationship_class(db_map, rel_name, object_class_ids)
            export_data(db_map, data, class)
        end
        db_map[:commit_session]("saved from julia")
        db_map[:session][:close]()
    catch err
        db_map[:rollback_session]()
        db_map[:session][:close]()
        throw(err)
    end
end

function JuMP_variables_to_spine_db(JuMP_vars::JuMP.JuMPDict{JuMP.Variable}, var_name::String, db_url::String, result_name::String)
    JuMP_vars_dict = Dict(var_name => JuMP_vars)
    JuMP_variables_to_spine_db(JuMP_vars_dict, db_url, result_name)
end

function JuMP_variables_to_spine_db(JuMP_vars::Array{JuMP.JuMPDict{JuMP.Variable},1}, var_name::Array{String,1}, db_url::String, result_name::String)
    JuMP_vars_dict = Dict(zip(var_name,JuMP_vars))
    JuMP_variables_to_spine_db(JuMP_vars_dict, db_url, result_name)
end
