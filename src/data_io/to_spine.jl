"""
    packed_var_dataframe(var::JuMP.JuMPDict{JuMP.Variable, N} where N)

A DataFrame from a JuMP variable, with the last column packed into a JSON.
"""
function packed_var_dataframe(var::JuMP.JuMPDict{JuMP.Variable, N} where N)
    var_dataframe = as_dataframe(getvalue(var))
    sort!(var_dataframe)
    packed_var_dataframe = by(var_dataframe, [1:size(var_dataframe, 2) - 2; ]) do df
        DataFrame(json=JSON.json(df[end]))
    end
end

"""
    add_var_to_result!(db_map::PyObject, var_name::Symbol, dataframe::DataFrame, result_class::PyObject, result_object::PyObject)

Update `db_map` with data given for `var_name` in `dataframe`,
by linking it to a `result_object` of class `result_class`.
"""
function add_var_to_result!(
        db_map::PyObject,
        var_name::Symbol,
        dataframe::DataFrame,
        result_class::PyObject,
        result_object::PyObject
    )
    # Iterate over first row in dataframe to retrieve object classes
    first_row = Array(dataframe[1, collect(1:size(dataframe, 2) - 1)])
    object_class_name_list = [py"""$result_class.name"""]
    object_class_id_list = [py"""$result_class.id"""]
    for object_name in first_row
        py"""object_ = $db_map.single_object(name=$object_name).one_or_none()
        """
        if py"object_" == nothing
            # Object not found, add object class named after it
            object_class_name = string(object_name, "_class")
            py"""object_class = $db_map.get_or_add_object_class(name=$object_class_name)
            """
            push!(object_class_name_list, object_class_name)
            push!(object_class_id_list, py"object_class.id")
        else
            py"""object_class = $db_map.single_object_class(id=object_.class_id).one_or_none()
            """
            push!(object_class_name_list, py"object_class.name")
            push!(object_class_id_list, py"object_class.id")
        end
    end
    # Get or add relationship `result__object_class1__object_class2__...`
    relationship_class_name = join(object_class_name_list, "__")
    # FIXME: Getting sql foreign key error when sending integers to python, sending floats seems to work
    float_object_class_id_list = convert.(Float64, object_class_id_list)
    py"""relationship_class = $db_map.get_or_add_wide_relationship_class(
        name=$relationship_class_name,
        object_class_id_list=$float_object_class_id_list)
    """
    parameter = py"relationship_class"
    # Get or add parameter named after variable
    py"""parameter = $db_map.get_or_add_parameter(
        name=$var_name,
        relationship_class_id=relationship_class.id)
    """
    parameter = py"parameter"
    # Sweep dataframe to add relationships and parameter values
    for row in eachrow(dataframe)
        object_name_list = [py"""$result_object.name"""]
        object_id_list = [py"""$result_object.id"""]
        for (field_name, object_name) in row[1:end-1]  # NOTE: last index contains the json, not needed here
            py"""object_ = $db_map.single_object(name=$object_name).one_or_none()
            """
            if py"object_" == nothing
                warn("Couldn't find object '$object_name', skipping row...")
                break
            end
            push!(object_name_list, object_name)
            push!(object_id_list, py"object_.id")
        end
        # Add relationship `result_object__object1__object2__...
        relationship_name = join(object_name_list, "__")
        # FIXME: Getting sql foreign key error when sending integers to python, sending floats seems to work
        float_object_id_list = convert.(Float64, object_id_list)
        py"""relationship = $db_map.add_wide_relationship(
            name=$relationship_name,
            object_id_list=$float_object_id_list,
            class_id=relationship_class.id)
        """
        # Add parameter value
        json = row[end]
        py"""$db_map.add_parameter_value(
            relationship_id=relationship.id,
            parameter_id=parameter.id,
            json=$json
        )
        """
    end
end

"""
    JuMP_results_to_spine_db!(db_url::String; results...)

Export JuMP variables into a spine database.
Find object and relationships using JuMP variables' keys and searching the database for exact matches.
Create new relationships and relationship classes if they don't already exists.
Create new result object with relationships to keys in JuMP variable.

Arguments:
    `db_url::String`: url of target database
    `results...`: Pairs of variable name, JuMP variable
"""
function JuMP_results_to_spine_db!(db_url::String; results...)
    # Start database connection and add a new commit
    db_map = py"""$db_api.DatabaseMapping($db_url)"""
    try
        result_class = py"""$db_map.get_or_add_object_class(name="result")"""
        timestamp = Dates.format(Dates.now(), "yyyymmdd_HH_MM_SS")
        result_name = join(["result", timestamp], "_")
        result_object = py"""$db_map.add_object(name=$result_name, class_id=$result_class.id)"""
        # Insert variable into spine database.
        for (name, var) in results
            dataframe = packed_var_dataframe(var)
            add_var_to_result!(db_map, name, dataframe, result_class, result_object)
        end
        msg = string("Save ", keys(results), " automatically from Spine Model.")
        py"""$db_map.commit_session($msg)"""
    catch err
        py"""$db_map.rollback_session()"""
        throw(err)
    end
end

"""
    copy_structure_and_add_results!(dest_url, source_url; results...)

Update `dest_url` with objects and relationships from `source_url`,
as well as new parameters from `results`.
"""
function copy_structure_and_add_results!(dest_url, source_url; results...)
    py"""$db_api.merge_database($dest_url, $source_url, skip_tables=["parameter", "parameter_value"])"""
    JuMP_results_to_spine_db!(dest_url; results...)
end
