#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


"""
    packed_var_dataframe(var::JuMP.JuMPDict{JuMP.Variable, N} where N)

A DataFrame from a JuMP variable, with the last column packed into a JSON.
"""
function packed_var_dataframe(var::Dict{Tuple, JuMP.Variable})
    var_dataframe = as_dataframe(Dict{Tuple, Float64}(k => getvalue(v) for (k, v) in var))
    sort!(var_dataframe)
    packed_var_dataframe = by(var_dataframe, [1:size(var_dataframe, 2) - 2; ]) do df
        DataFrame(json=JSON.json(df[end]))
    end
end

"""
    add_var_to_result!(db_map::PyObject, var_name::Symbol, dataframe::DataFrame, result_class::Dict, result_object::Dict)

Update `db_map` with data given for `var_name` in `dataframe`,
by linking it to a `result_object` of class `result_class`.
"""
function add_var_to_result!(
        db_map::PyObject,
        var_name::Symbol,
        dataframe::DataFrame,
        result_class::Dict,
        result_object::Dict
    )
    # Iterate over first row in dataframe to retrieve object classes
    first_row = Array(dataframe[1, collect(1:size(dataframe, 2) - 1)])
    object_class_name_list = PyVector(py"""[$result_class['name']]""")
    object_class_id_list = PyVector(py"""[$result_class['id']]""")
    for object_name in first_row
        py"""object_ = $db_map.single_object(name=$object_name).one_or_none()
        """
        if py"object_" != nothing
            py"""object_class = $db_map.single_object_class(id=object_.class_id).one_or_none()
            """
            if py"object_class" != nothing
                push!(object_class_name_list, py"object_class.name")
                push!(object_class_id_list, py"object_class.id")
                continue
            end
        end
        # Object or class not found, add dummy object class named after the object
        object_class_name = string(object_name, "_class")
        py"""object_class = $db_map.get_or_add_object_class(name=$object_class_name)
        """
        push!(object_class_name_list, object_class_name)
        push!(object_class_id_list, py"object_class.id")
    end
    # Get or add relationship class `result__object_class1__object_class2__...`
    relationship_class_name = join(object_class_name_list, "__")
    py"""relationship_class = $db_map.get_or_add_wide_relationship_class(
        name=$relationship_class_name,
        object_class_id_list=$object_class_id_list)
    """
    # Get or add parameter named after variable
    py"""parameter = $db_map.get_or_add_parameter(
        name=$var_name,
        relationship_class_id=relationship_class.id)
    """
    parameter = py"parameter"
    # Sweep dataframe to add relationships and parameter values
    for row in eachrow(dataframe)
        object_name_list = PyVector(py"""[$result_object['name']]""")
        object_id_list = PyVector(py"""[$result_object['id']]""")
        for (field_name, object_name) in row[1:end-1]  # NOTE: last index contains the json, not needed for the name
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
        py"""relationship = $db_map.add_wide_relationship(
            name=$relationship_name,
            object_id_list=$object_id_list,
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

Update `dest_url` with new parameters from `results`.
Find objects and relationships using results' keys and searching the database for exact matches.
Create new relationships and relationship classes if they don't already exist.
Create new result object with relationships to keys in results.

Arguments:
    `db_url::String`: url of target database
    `results...`: Pairs of variable name, JuMP variable
"""
function JuMP_results_to_spine_db!(db_url::String; results...)
    db_map = py"""$db_api.DiffDatabaseMapping($db_url, 'spine_model')"""
    try
        result_class = py"""$db_map.get_or_add_object_class(name="result")._asdict()"""
        timestamp = Dates.format(Dates.now(), "yyyymmdd_HH_MM_SS")
        result_name = join(["result", timestamp], "_")
        result_object = py"""$db_map.add_object(name=$result_name, class_id=$result_class['id'])._asdict()"""
        # Insert variable into spine database.
        for (name, var) in results
            dataframe = packed_var_dataframe(var)
            add_var_to_result!(db_map, name, dataframe, result_class, result_object)
        end
        msg = string("Save ", join([string(k) for (k, v) in results], ", "), ", automatically from Spine Model.")
        py"""$db_map.commit_session($msg)"""
    catch err
        py"""$db_map.rollback_session()"""
        throw(err)
    finally
        py"""$db_map.close()"""
    end
end

"""
    JuMP_results_to_spine_db!(dest_url, source_url; results...)

Update `dest_url` with objects and relationships from `source_url`,
as well as new parameters from `results`.
"""
function JuMP_results_to_spine_db!(dest_url, source_url; results...)
    if py"""$db_api.is_unlocked($dest_url)"""
        py"""$db_api.merge_database($dest_url, $source_url, skip_tables=["parameter", "parameter_value"])"""
        JuMP_results_to_spine_db!(dest_url; results...)
    else
        warn(string("The current operation cannot proceed because the SQLite database '$dest_url' is locked. \n",
            "The operation will resume automatically if the lock is released within the next 2 minutes."))
        if py"""$db_api.is_unlocked($dest_url, timeout=120)"""
            py"""$db_api.merge_database($dest_url, $source_url, skip_tables=["parameter", "parameter_value"])"""
            JuMP_results_to_spine_db!(dest_url; results...)
        else
            timestamp = Dates.format(Dates.now(), "yyyymmdd_HH_MM_SS")
            alt_dest_url = "sqlite:///result_$timestamp.sqlite"
            info("The database $dest_url is locked. Saving results to $alt_dest_url instead.")
            py"""$db_api.merge_database($alt_dest_url, $source_url, skip_tables=["parameter", "parameter_value"])"""
            JuMP_results_to_spine_db!(alt_dest_url; results...)
        end
    end
end
