"""
    JuMP_all_out(db_url)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the database
given by `db_url`. `db_url` is a database url composed according to
[sqlalchemy rules](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls).
See [`JuMP_all_out(mapping::PyObject)`](@ref) for details
about the generated convenience functions.
"""
function JuMP_all_out(db_url)
    mapping = db_api[:DatabaseMapping](db_url)
    JuMP_all_out(mapping)
end

"""
Append an increasing integer to object classes that are repeated (eg, commodity1, commodity2)
"""
function fix_name_ambiguity(object_class_name_list)
    ref_object_class_name_list = copy(object_class_name_list)
    object_class_name_ocurrences = Dict{String,Int64}()
    for (i, object_class_name) in enumerate(object_class_name_list)
        n_ocurrences = count(x -> x == object_class_name, ref_object_class_name_list)
        n_ocurrences == 1 && continue
        ocurrence = get(object_class_name_ocurrences, object_class_name, 1)
        object_class_name_list[i] = string(object_class_name, ocurrence)
        object_class_name_ocurrences[object_class_name] = ocurrence + 1
    end
end

function JuMP_object_out(mapping::PyObject)
    object_class_list = py"$mapping.object_class_list()"
    for object_class in py"[x._asdict() for x in $object_class_list]"
        object_class_id = object_class["id"]
        object_class_name = object_class["name"]
        object_list = py"$mapping.object_list(class_id=$object_class_id)"
        object_names = py"[x.name for x in $object_list]"
        @suppress_err begin
            @eval begin
                $(Symbol(object_class_name))() = $(object_names)
                export $(Symbol(object_class_name))
            end
        end
    end
end

function JuMP_relationship_out(mapping::PyObject)
    relationship_class_list = py"$mapping.wide_relationship_class_list()"
    for relationship_class in py"[x._asdict() for x in $relationship_class_list]"
        relationship_class_id = relationship_class["id"]
        relationship_class_name = relationship_class["name"]
        object_class_name_list = [String(x) for x in split(relationship_class["object_class_name_list"], ",")]
        fix_name_ambiguity(object_class_name_list)
        relationship_list = py"$mapping.wide_relationship_list(class_id=$relationship_class_id)"
        object_name_lists = Array{Array{String,1},1}()
        for relationship in py"[x._asdict() for x in $relationship_list]"
            object_name_list = [String(x) for x in split(relationship["object_name_list"], ",")]
            push!(object_name_lists, object_name_list)
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(relationship_class_name))(;kwargs...)
                    result = $(object_name_lists)
                    object_class_name_list = $(object_class_name_list)
                    for (key,value) in kwargs
                        index = findfirst(x -> x == string(key), object_class_name_list)
                        @show string(key)
                        @show object_class_name_list
                        result = filter(x -> x[index] == value, result)
                        result = [x[1:end .!= index] for x in result]
                    end
                    [size(x, 1) == 1?x[1]:x for x in result]
                end
                export $(Symbol(relationship_class_name))
            end
        end
    end
end

function JuMP_object_parameter_out(mapping::PyObject)
    parameter_list = py"$mapping.parameter_list()"
    for parameter in py"[x._asdict() for x in $parameter_list]"
        parameter_name = parameter["name"]
        count_ = py"$mapping.object_parameter_value_list(parameter_name=$parameter_name).count()"
        count_ == 0 && continue
        object_parameter_value_list =
            py"$mapping.object_parameter_value_list(parameter_name=$parameter_name)"
        object_parameter_value_dict = Dict{String,Any}()
        for object_parameter_value in py"[x._asdict() for x in $object_parameter_value_list]"
            object_name = object_parameter_value["object_name"]
            json = try
                JSON.parse(object_parameter_value["json"])
            catch LoadError
                nothing
            end
            value = object_parameter_value["value"]
            object_parameter_value_dict[object_name] = Dict{String,Any}(
                "json" => json,
                "value" => as_number(value)
            )
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    length(kwargs) != 1 && return nothing
                    key, value = kwargs[1]
                    object_parameter_value_dict = $(object_parameter_value_dict)
                    object_class_name = string(key)  # NOTE: not in use at the moment
                    object_name = value
                    !haskey(object_parameter_value_dict, object_name) && return nothing
                    result = object_parameter_value_dict[object_name]
                    result["json"] == nothing && return result["value"]
                    return result["json"][t]
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end

function JuMP_relationship_parameter_out(mapping::PyObject)
    parameter_list = py"$mapping.parameter_list()"
    for parameter in py"[x._asdict() for x in $parameter_list]"
        parameter_name = parameter["name"]
        count_ = py"$mapping.relationship_parameter_value_list(parameter_name=$parameter_name).count()"
        count_ == 0 && continue
        relationship_parameter_value_list =
            py"$mapping.relationship_parameter_value_list(parameter_name=$parameter_name)"
        # Get object_class_name_list from first row in the result
        object_class_name_list = nothing
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_class_name_list = [
                String(x) for x in split(relationship_parameter_value["object_class_name_list"], ",")
            ]
            break
        end
        fix_name_ambiguity(object_class_name_list)
        relationship_parameter_value_dict = Dict{String,Any}()
        for relationship_parameter_value in py"[x._asdict() for x in $relationship_parameter_value_list]"
            object_name_list = relationship_parameter_value["object_name_list"]
            json = try
                JSON.parse(relationship_parameter_value["json"])
            catch LoadError
                nothing
            end
            value = relationship_parameter_value["value"]
            relationship_parameter_value_dict[object_name_list] = Dict{String,Any}(
                "json" => json,
                "value" => as_number(value)
            )
        end
        @suppress_err begin
            @eval begin
                function $(Symbol(parameter_name))(;t::Int64=1, kwargs...)
                    relationship_parameter_value_dict = $(relationship_parameter_value_dict)
                    object_class_name_list = $(object_class_name_list)
                    kwargs_dict = Dict(kwargs)
                    object_name_list = Array{String,1}()
                    for object_class_name in object_class_name_list
                        if haskey(kwargs_dict, Symbol(object_class_name))
                            push!(object_name_list, kwargs_dict[Symbol(object_class_name)])
                            continue
                        end
                    end
                    object_name_list = join(object_name_list, ",")
                    !haskey(relationship_parameter_value_dict, object_name_list) && return nothing
                    result = relationship_parameter_value_dict[object_name_list]
                    result["json"] == nothing && return result["value"]
                    return result["json"][t]
                end
                export $(Symbol(parameter_name))
            end
        end
    end
end

"""
    JuMP_all_out(mapping::PyObject)

Generate and export convenience functions
for each object class, relationship class, and parameter, in the
database given by `mapping`. `mapping` is an instance of `DatabaseMapping`
provided by [`spinedatabase_api`](https://gitlab.vtt.fi/spine/data/tree/database_api).
The convenience functions are called as follows:

  - **object class**: call `x()` to get the set of names of objects of the class named `x`.
  - **relationship class**: call `y()` to get the set of name tuples of objects related by the
    relationship class named `"y"`; also call `y(object_class_name="object_name")` to get the
    set of name tuples of objects related to "object_name".
  - **parameter**: call `z("k", t)` to get the value of the parameter named `"z"` for the object
    named `"k"`, or `Nullable()` if the parameter is not defined.
    If this value is an array in the Spine object, then `z("k", t)` returns position `t` in that array.

# Example
```julia
julia> JuMP_all_out(db_url)
julia> commodity()
3-element Array{String,1}:
 "coal"
 "gas"
...
julia> unit_node(node="Leuven")
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> conversion_cost(unit="gas_import")
12
julia> demand(node="Leuven", t=17)
700
```
"""
function JuMP_all_out(mapping::PyObject)
    JuMP_object_out(mapping)
    JuMP_relationship_out(mapping)
    JuMP_object_parameter_out(mapping)
    JuMP_relationship_parameter_out(mapping)
end
