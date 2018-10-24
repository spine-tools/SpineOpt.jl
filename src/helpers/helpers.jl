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
    @suppress_err expr
Suppress the STDERR stream for the given expression.
"""
# NOTE: Borrowed from Suppressor.jl
macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end


"""
    as_number(str)

An Int64 or Float64 from parsing `str` if possible.
"""
function as_number(str)
    typeof(str) != String && return str
    type_array = [
        Int64,
        Float64,
    ]
    for T in type_array
        try
            return parse(T, str)
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
    fix_name_ambiguity!(object_class_name_list)

Append an increasing integer to repeated object class names.

# Example
```julia
julia> s=["connection","node", "node"]
3-element Array{String,1}:
 "connection"
 "node"
 "node"

julia> SpineModel.fix_name_ambiguity!(s)

julia> s
3-element Array{String,1}:
 "connection"
 "node1"
 "node2"
```
"""
# NOTE: Do we really need to document this one?
function fix_name_ambiguity!(object_class_name_list::Array{String,1})
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

function fix_name_ambiguity!(object_class_name_list::Array{Symbol,1})
    ref_object_class_name_list = copy(object_class_name_list)
    object_class_name_ocurrences = Dict{Symbol,Int64}()
    for (i, object_class_name) in enumerate(object_class_name_list)
        n_ocurrences = count(x -> x == object_class_name, ref_object_class_name_list)
        n_ocurrences == 1 && continue
        ocurrence = get(object_class_name_ocurrences, object_class_name, 1)
        object_class_name_list[i] = Symbol(object_class_name, ocurrence)
        object_class_name_ocurrences[object_class_name] = ocurrence + 1
    end
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
    expression = macroexpand(esc(expression))
    call_location = Dict{Expr,Array{Dict{String,Any},1}}()
    assignment_location = Dict{Symbol,Array{Dict{String,Any},1}}()
    replacement_variable_location = Array{Any,1}()
    # 'Beat' each node in the expression tree (see definition of `beat` below)
    visit_node(expression, 1, nothing, 1, beat, call_location, assignment_location)
    for (call, call_location_arr) in call_location
        # Find top-most node where all arguments have been assigned
        local topmost_node_id
        call_arg_arr = []  # Array of non-literal arguments
        arg_assignment_location = Dict() # Location of each argument assignment
        replacement_variable = Dict()  # Variable to store the return value of each relocated call
        for arg in call.args[2:end]  # First arg is the method name
            if isa(arg, Symbol)
                # Positional argument
                push!(call_arg_arr, arg)
            elseif isa(arg, Expr) && arg.head == :kw && isa(arg.args[end], Symbol)
                # keyword argument
                push!(call_arg_arr, arg.args[end])
            elseif isa(arg, Expr) && arg.head == :parameters
                # keyword arguments after a semi-colon
                for kwarg in arg.args
                    if kwarg.head == :kw && isa(kwarg.args[end], Symbol)
                        push!(call_arg_arr, kwarg.args[end])
                    end
                end
            end
        end
        isempty(call_arg_arr) && continue
        topmost_node_id = try maximum(
            minimum(
                location["node_id"] for location in assignment_location[arg]
            ) for arg in call_arg_arr
        )
        catch KeyError
            # One of the arguments is not assigned in this scope, skip the call
            continue
        end
        for arg in call_arg_arr
            for location in assignment_location[arg]
                location["node_id"] < topmost_node_id && continue
                push!(arg_assignment_location, location["node_id"] => (location["parent"], location["row"]))
            end
        end
        # Find better place to put the call
        for location in call_location_arr
            target_node_id = try
                maximum(x for x in keys(arg_assignment_location) if x < location["node_id"])
            catch ArgumentsError
                # One or more arguments are not assigned before the call is made, skip
                continue
            end
            # Check if recursive assignment, e.g., x = f(x), and skip it
            target_parent, target_row = arg_assignment_location[target_node_id]
            target_parent.args[target_row].args[end] == call && continue
            # Create or retrieve replacement variable
            x = get!(replacement_variable, target_node_id, gensym())
            # Add new replacement variable location
            push!(replacement_variable_location, (x, location["parent"], location["row"]))
        end
        # Perform the call at a better location, assign result to replacement variable
        for (target_node_id, x) in replacement_variable
            target_parent, target_row = arg_assignment_location[target_node_id]
            if target_parent.head in (:for, :while)  # Assignment is in the loop condition, e.g., for i=1:100
                # Better location is the begining of the loop body
                target_parent.args[target_row + 1] = Expr(:block, :($x = $call), target_parent.args[target_row + 1])
            else
                # Better location is right after the assignment
                target_parent.args[target_row] = Expr(:block, target_parent.args[target_row], :($x = $call))
            end  # TODO: are there any other cases which need special treatment?
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
    end
    try
        sibling = parent.args[row + 1]
        visit_node(sibling, node_id + 1, parent, row + 1, func, func_args...; func_kwargs...)
    end
end
