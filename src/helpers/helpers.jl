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


struct TimePattern
    y::Union{Array{UnitRange{Int64},1},Nothing}
    m::Union{Array{UnitRange{Int64},1},Nothing}
    d::Union{Array{UnitRange{Int64},1},Nothing}
    wd::Union{Array{UnitRange{Int64},1},Nothing}
    H::Union{Array{UnitRange{Int64},1},Nothing}
    M::Union{Array{UnitRange{Int64},1},Nothing}
    S::Union{Array{UnitRange{Int64},1},Nothing}
    TimePattern(;y=nothing, m=nothing, d=nothing, wd=nothing, H=nothing, M=nothing, S=nothing) = new(y, m, d, wd, H, M, S)
end


function Base.show(io::IO, time_pattern::TimePattern)
    d = Dict{Symbol,String}(
        :y => "year",
        :m => "month",
        :d => "day",
        :wd => "day of the week",
        :H => "hour",
        :M => "minute",
        :S => "second",
    )
    ranges = Array{String,1}()
    for field in fieldnames(TimePattern)
        value = getfield(time_pattern, field)
        if value != nothing
            str = "$(d[field]) from "
            str *= join(["$(x.start) to $(x.stop)" for x in value], ", or ")
            push!(ranges, str)
        end
    end
    print(io, join(ranges, ",\nand "))
end


struct TimePatternError <: Exception
    msg::String
end


function parse_json(json)
    parsed_json = JSON.parse(json)  # Let LoadError be thrown
    # Do some validation, to advance work for the convenience function
    if parsed_json isa Dict
        haskey(parsed_json, "type") || error("'type' missing")
        type_ = parsed_json["type"]
        if type_ == "time_pattern"
            haskey(parsed_json, "data") || error("'data' missing")
            parsed_json["data"] isa Dict || error("'data' should be a dictionary (time_pattern: value)")
            parsed_json["time_pattern_data"] = Dict{Union{TimePattern,String},Any}()
            # Try and parse String keys as TimePatterns into a new dictionary
            for (k, v) in pop!(parsed_json, "data")
                new_k = try
                    parse_time_pattern(k)
                catch e
                    k
                end
                parsed_json["time_pattern_data"][new_k] = v
            end
        else
            error("unknown type '$type_'")
        end
    end
    parsed_json
end


function parse_date_time_str(str::String)
    reg_exp = r"[ymdHMS]"
    keys = [m.match for m in eachmatch(reg_exp, str)]
    values = split(str, reg_exp; keepempty=false)
    periods = Array{Period,1}()
    for (k, v) in zip(keys, values)
        k == "y" && push!(periods, Year(v))
        k == "m" && push!(periods, Month(v))
        k == "d" && push!(periods, Day(v))
        k == "H" && push!(periods, Hour(v))
        k == "M" && push!(periods, Minute(v))
        k == "S" && push!(periods, Second(v))
    end
    DateTime(periods...)
end


function parse_time_pattern(spec)
    spec isa String || throw(TimePatternError("""invalid type, expected String, got $(typeof(spec))."""))
    union_op = ","
    intersection_op = ";"
    range_op = "-"
    kwargs = Dict()
    regexp = r"(y|m|d|wd|H|M|S)"
    pattern_specs = split(spec, union_op)
    for pattern_spec in pattern_specs
        range_specs = split(pattern_spec, intersection_op)
        for range_spec in range_specs
            m = match(regexp, range_spec)
            m === nothing && throw(TimePatternError("""invalid interval specification $range_spec."""))
            key = m.match
            start_stop = range_spec[length(key)+1:end]
            start_stop = split(start_stop, range_op)
            length(start_stop) != 2 && throw(TimePatternError("""invalid interval specification $range_spec."""))
            start_str, stop_str = start_stop
            start = try
                parse(Int64, start_str)
            catch ArgumentError
                throw(TimePatternError("""invalid lower bound $start_str."""))
            end
            stop = try
                parse(Int64, stop_str)
            catch ArgumentError
                throw(TimePatternError("""invalid upper bound $stop_str."""))
            end
            start > stop && throw(TimePatternError("""lower bound can't be higher than upper bound."""))
            arr = get!(kwargs, Symbol(key), Array{UnitRange{Int64},1}())
            push!(arr, range(start, stop=stop))
        end
    end
    TimePattern(;kwargs...)
end


matches(time_pattern::TimePattern, str::String) = matches(time_pattern, parse_date_time_str(str))


"""
    matches(time_pattern::TimePattern, t::DateTime)

true if `time_pattern` matches `t`, false otherwise.
For every range specified in `time_pattern`, `t` has to be in that range.
If a range is not specified for a given level, then it doesn't matter where
(or should I say, *when*?) is `t` on that level.
"""
function matches(time_pattern::TimePattern, t::DateTime)
    conds = Array{Bool,1}()
    time_pattern.y != nothing && push!(conds, any(year(t) in rng for rng in time_pattern.y))
    time_pattern.m != nothing && push!(conds, any(month(t) in rng for rng in time_pattern.m))
    time_pattern.d != nothing && push!(conds, any(day(t) in rng for rng in time_pattern.d))
    time_pattern.wd != nothing && push!(conds, any(dayofweek(t) in rng for rng in time_pattern.wd))
    time_pattern.H != nothing && push!(conds, any(hour(t) in rng for rng in time_pattern.H))
    time_pattern.M != nothing && push!(conds, any(minute(t) in rng for rng in time_pattern.M))
    time_pattern.S != nothing && push!(conds, any(second(t) in rng for rng in time_pattern.S))
    all(conds)
end


"""
    parse_value(str)

An Int64 or Float64 from `str`, if possible.
"""
function parse_value(str)
    typeof(str) != String && return str
    type_array = [
        Int64,
        Float64,
    ]
    for T in type_array
        try
            return parse(T, str)
        catch
        end
    end
    str
end

"""
    as_dataframe(var::Dict{Tuple,Float64})

A DataFrame from a Dict, with keys in first N columns and value in the last column.
"""
function as_dataframe(var::Dict{Tuple,Float64})
    var_keys = keys(var)
    first_key = first(var_keys)
    column_types = vcat([typeof(x) for x in first_key], typeof(var[first_key...]))
    key_count = length(first_key)
    df = DataFrame(column_types, length(var))
    for (i, key) in enumerate(var_keys)
        for k in 1:key_count
            df[i, k] = key[k]
        end
        df[i, end] = var[key...]
    end
    return df
end


"""
    fix_name_ambiguity(object_class_name_list)

A list identical to `object_class_name_list`, except that repeated entries are modified by
appending an increasing integer.

# Example
```julia
julia> s=[:connection, :node, :node]
3-element Array{Symbol,1}:
 :connection
 :node
 :node

julia> fix_name_ambiguity(s)
3-element Array{Symbol,1}:
 :connection
 :node1
 :node2
```
"""
function fix_name_ambiguity(object_class_name_list::Array{Symbol,1})
    fixed = Array{Symbol,1}()
    object_class_name_ocurrences = Dict{Symbol,Int64}()
    for (i, object_class_name) in enumerate(object_class_name_list)
        n_ocurrences = count(x -> x == object_class_name, object_class_name_list)
        if n_ocurrences == 1
            push!(fixed, object_class_name)
        else
            ocurrence = get(object_class_name_ocurrences, object_class_name, 1)
            push!(fixed, Symbol(object_class_name, ocurrence))
            object_class_name_ocurrences[object_class_name] = ocurrence + 1
        end
    end
    fixed
end


"""
    @butcher expression

Butcher an expression so that method calls involving one or more arguments
are performed as soon as those arguments are available. Needs testing.

For instance, an expression like this:

```
x = 5
for i=1:1e6
    y = f(x)
end
```

is turned into something like this:

```
x = 5
ret = f(x)
for i=1:1e6
    y = ret
end
```

This is mainly intended to improve performance in cases where the implementation
of a method is expensive, but for readability reasons the programmer wants to call it
at unconvenient places -such as the body of a long for loop.
"""
# TODO: sometimes methods are called with arguments which are themselves method calls,
# e.g., f(g(x)). This can be butchered by doing multiple passages, but I wonder if
# it's possible in a single passage. Anyways, we could have a keyword argument
# to indicate the number of passages to perform. Also, we can make it so if this
# argument is Inf (or something) we keep going until there's nothing left to butcher.
macro butcher(expression)
    expression = macroexpand(SpineModel, esc(expression))
    call_location = Dict{Expr,Array{Dict{String,Any},1}}()
    assignment_location = Dict{Symbol,Array{Dict{String,Any},1}}()
    replacement_variable_location = Array{Any,1}()
    # 'Beat' each node in the expression tree (see definition of `beat` below)
    visit_node(expression, 1, nothing, 1, beat, call_location, assignment_location)
    for (call, call_location_arr) in call_location
        call_arg_arr = []  # Array of non-literal arguments
        replacement_variable = Dict()  # Variable to store the return value of each relocated call
        for arg in call.args[2:end]  # First arg is the method name
            if isa(arg, Symbol)
                # Positional argument
                push!(call_arg_arr, arg)
            elseif isa(arg, Expr)
                if arg.head == :kw
                    # Keyword argument, push it if Symbol
                    isa(arg.args[end], Symbol) && push!(call_arg_arr, arg.args[end])
                elseif arg.head == :tuple
                    # Tuple argument, append every Symbol
                    append!(call_arg_arr, [x for x in arg.args if isa(x, Symbol)])
                elseif arg.head == :parameters
                    # keyword arguments after a semi-colon
                    for kwarg in arg.args
                        if kwarg.head == :kw
                            isa(kwarg.args[end], Symbol) && push!(call_arg_arr, kwarg.args[end])
                        end
                    end
                else
                    # TODO: Handle remaining cases
                end
            else
                # TODO: Handle remaining cases
            end
        end
        isempty(call_arg_arr) && continue
        # Find top-most node where all arguments are assigned
        topmost_node_id = try maximum(
            minimum(
                location["node_id"] for location in assignment_location[arg]
            ) for arg in call_arg_arr
        )
        catch KeyError
            # One of the arguments is not assigned in this scope, skip the call
            continue
        end
        # Build dictionary of places where arguments are reassigned
        # below the top-most node
        arg_assignment_location = Dict()
        for arg in call_arg_arr
            for location in assignment_location[arg]
                location["node_id"] < topmost_node_id && continue
                push!(arg_assignment_location, location["node_id"] => (location["parent"], location["row"]))
            end
        end
        # Find better place for the call
        for location in call_location_arr
            # Make sure we use the most recent value of all the arguments (take maximum)
            target_node_id = try
                maximum(x for x in keys(arg_assignment_location) if x < location["node_id"])
            catch ArgumentsError
                # One or more arguments are not assigned before the call is made, skip
                continue
            end
            target_parent, target_row = arg_assignment_location[target_node_id]
            # Only relocate if we have a recipe for it (see for loop right below this one)
            !in(target_parent.head, (:for, :while, :block)) && continue
            # Don't relocate recursive assignment, e.g., x = f(x)
            target_parent.args[target_row].args[end] == call && continue
            # Create or retrieve replacement variable
            x = get!(replacement_variable, target_node_id, gensym())
            # Add new location for the replacement variable
            push!(replacement_variable_location, (x, location["parent"], location["row"]))
        end
        # Put the call at a better location, assign result to replacement variable
        for (target_node_id, x) in replacement_variable
            target_parent, target_row = arg_assignment_location[target_node_id]
            if target_parent.head in (:for, :while)  # Assignment is in the loop condition, e.g., for i=1:100
                # Put call at the begining of the loop body
                target_parent.args[target_row + 1] = Expr(:block, :($x = $call), target_parent.args[target_row + 1])
            elseif target_parent.head == :block
                # Put call right after the assignment
                target_parent.args[target_row] = Expr(:block, target_parent.args[target_row], :($x = $call))
            end
        end
    end
    # Replace calls in original locations with the replacement variable
    for (x, parent, row) in replacement_variable_location
        parent.args[row] = :($x)
    end
    expression
end

"""
    beat(node::Any, node_id::Int64, parent::Any, row::Int64,
         call_location::Dict{Expr,Array{Dict{String,Any},1}},
         assignment_location = Dict{Symbol,Array{Dict{String,Any},1}})

Beat an expression node in preparation for butchering:
 1. Turn for loops with multiple iteration specifications into multiple nested for loops.
 E.g., `for i=1:10, j=1:5 (body) end` is turned into `for i=1:10 for j=1:5 (body) end end`.
 This is so @butcher can place method calls *in between* iteration specifications.
 2. Register the location of calls and assignments into the supplied dictionaries.
"""
function beat(
        node::Any, node_id::Int64, parent::Any, row::Int64,
        call_location::Dict{Expr,Array{Dict{String,Any},1}},
        assignment_location = Dict{Symbol,Array{Dict{String,Any},1}})
    !isa(node, Expr) && return
    # 'Splat' for loop
    if node.head == :for && node.args[1].head == :block
        iteration_specs = node.args[1].args
        # Turn all specs but first into for loops of their own and prepend them to the body
        for spec in iteration_specs[end:-1:2]
            node.args[2] = Expr(:for, spec, node.args[2])
        end
        # Turn first spec into the condition of the outer-most (original) loop
        node.args[1] = iteration_specs[1]
    # Register call location (node_id, parent and row), but only if it has arguments
    elseif node.head == :call && length(node.args) > 1  # First arg is the method name
        call_location_arr = get!(call_location, node, Array{Dict{String,Any},1}())
        push!(
            call_location_arr,
            Dict{String,Any}(
                "node_id" => node_id,
                "parent" => parent,
                "row" => row
            )
        )
    # Register assignment location (node_id, parent and row)
    elseif node.head == :(=)
        variable_arr = []  # Array of variables being assigned
        if isa(node.args[1], Symbol)
            # Single assignment, e.g., a = 1
            variable_arr = [node.args[1]]
        elseif isa(node.args[1], Expr)
            # Multiple assignment
            if node.args[1].head == :tuple
                # Tupled form, all args are assigned, e.g., a, b = 1, "foo"
                variable_arr = node.args[1].args
            else
                # Other bracketed form, only first arg is assigned, e.g., v[a, b] = "bar"
                variable_arr = [node.args[1].args[1]]
            end
        end
        for var in variable_arr
            assignment_location_arr = get!(assignment_location, var, Array{Dict{String,Any},1}())
            push!(
                assignment_location_arr,
                Dict{String,Any}(
                    "node_id" => node_id,
                    "parent" => parent,
                    "row" => row
                )
            )
        end
    end
end

"""
    visit_node(node::Any, node_id::Int64, parent::Any, row::Int64, func, func_args...; func_kwargs...)

Recursively visit every node in an expression tree while applying a function on it.
"""
function visit_node(node::Any, node_id::Int64, parent::Any, row::Int64, func, func_args...; func_kwargs...)
    func(node, node_id, parent, row, func_args...; func_kwargs...)
    try
        child = node.args[1]
        visit_node(child, node_id + 1, node, 1, func, func_args...; func_kwargs...)
    catch
    end
    try
        sibling = parent.args[row + 1]
        visit_node(sibling, node_id + 1, parent, row + 1, func, func_args...; func_kwargs...)
    catch
    end
end
