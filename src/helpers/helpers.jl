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
    as_dataframe(v::JuMP.JuMPDict{Float64, N} where N)

A DataFrame from a JuMPDict, with keys in first N columns and value in the last column.
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
Append an increasing integer to object classes that are repeated.

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
function fix_name_ambiguity!(object_class_name_list)
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


"""
    @butcher expression

Butcher a expression so that method calls involving one or more arguments
are performed as soon as those arguments are available. The return value
is stored in a variable which replaces the original method calls. Needs testing.

For instance, an expression like:

```
x = 5
for i=1:1e6
    y = f(x)
end
```

is turned into:

```
x = 5
ret = f(x)
for i=1:1e6
    y = ret
end
```

This is mainly intended to improve performance in cases where the implementation
of `f()` is expensive, but for readability reasons, the programmer wants to call it
in an unconvenient place such as a long `for` loop.
"""
# NOTE: sometimes methods are called with arguments which are themselves method calls,
# e.g., f(g(x)). This can be butchered by doing multiple passages, but I wonder if
# it's possible in a single passage. Anyways, we could have a keyword argument
# to indicate the number of passages to perform. Also, we can make it so if this
# argument is Inf (or st) we keep going until there's nothing left to butcher.
macro butcher(expression)
    @show expression = macroexpand(esc(expression))
    parent = []  # Visited parents
    row = []  # Visited parent rows
    call_location = Dict{Expr,Array{Dict{String,Any},1}}()  # Function calls and their location
    assignment_location = Dict{Symbol,Array{Dict{String,Any},1}}()  # Assignments and their location
    visited = expression  # Node being visited
    back_to_parent = false  # `true` when going back from child to parent
    node_id = 0  # Node identifier, autoincremented
    # Visit the expression tree
    while true
        node_id += 1
        # Inspect node to retrieve information, but only when going down
        if isa(visited, Expr) && !back_to_parent
            # Store call locations (node_id, parent and row), but only for calls with arguments
            if visited.head == :call && length(visited.args) > 1  # First arg is the method name
                call_location_arr = get!(call_location, visited, Array{Dict{String,Any},1}())
                push!(
                    call_location_arr,
                    Dict{String,Any}(
                        "node_id" => node_id,
                        "parent" => parent[end],
                        "row" => row[end]
                    )
                )
            # Store assignment locations (node_id, parent and row)
            elseif visited.head == :(=)
                var_arr = []  # Array of variables being assigned
                if isa(visited.args[1], Expr)  # Multiple assignment
                    if visited.args[1].head == :tuple
                        # Tupled form, all args are assigned, e.g., a, b = 1, "foo"
                        var_arr = visited.args[1].args
                    else
                        # Other bracketed form, only first arg is assigned, e.g., v[a, b] = "bar"
                        var_arr = [visited.args[1].args[1]]
                    end
                elseif isa(visited.args[1], Symbol)  # Single assignment, e.g., a = 1
                    var_arr = [visited.args[1]]
                end
                for var in var_arr
                    assignment_location_arr = get!(assignment_location, var, Array{Dict{String,Any},1}())
                    push!(
                        assignment_location_arr,
                        Dict{String,Any}(
                            "node_id" => node_id,
                            "parent" => parent[end],
                            "row" => row[end]
                        )
                    )
                end
            end
        end
        # Visit next node in tree
        if !back_to_parent
            # Try and visit first child
            if isa(visited, Expr) && !isempty(visited.args)
                push!(parent, visited)
                push!(row, 1)
                visited = visited.args[1]
                back_to_parent = false
                continue
            end
        end
        # Try and visit next sibling if any; else, go back to parent
        try
            row[end] += 1
            visited = parent[end].args[row[end]]
            back_to_parent = false
            continue
        catch BoundsError
            pop!(row)
            visited = pop!(parent)
            (visited == expression) && break
            back_to_parent = true
            continue
        end
    end
    # Done visiting, now butcher expression
    replacement_variable_location = Array{Any,1}()  # Replacement variables and location where to insert them
    # NOTE: Assume, for now, that each variable is assigned only once
    for (call, call_location_arr) in call_location
        # Find first node where all arguments have been assigned
        call_arg_arr = []  # Array of non-literal arguments
        local node0_id  # Id of first node where all arguments have been assigned
        arg_assignment_location = Dict() # Id of node where each argument is assigned, and corresponding parent, row
        for arg in call.args[2:end]  # First arg is the method name
            if isa(arg, Symbol)
                # Positional argument
                push!(call_arg_arr, arg)
            elseif isa(arg, Expr) && arg.head == :kw && isa(arg.args[end], Symbol)
                # keyword argument
                push!(call_arg_arr, arg.args[end])
            elseif isa(arg, Expr)

            end
        end
        isempty(call_arg_arr) && continue
        node0_id = try maximum(
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
                location["node_id"] < node0_id && continue
                push!(arg_assignment_location, location["node_id"] => (location["parent"], location["row"]))
            end
        end
        for call_location_ in call_location_arr
            # Find better place to put the call
            target_node_id = try
                maximum(x for x in keys(arg_assignment_location) if x < call_location_["node_id"])
            catch ArgumentsError
                # One or more arguments are not assigned before the call is made, skip
                continue
            end
            @show call, target_node_id
            target_parent, target_row = arg_assignment_location[target_node_id]
            if target_parent.args[target_row].args[end] == call
                # Recursive assignment, e.g., x = f(x), skip it
                continue
            end
            # Perform the call at a better location, assign result to a variable
            x = gensym()
            if target_parent.head == :for  # Assignment is in the loop condition
                # Better location is at the begining of the loop body
                target_parent.args[target_row + 1] = Expr(:block, :($x = $call), target_parent.args[target_row + 1])
            else  # TODO: are there any other case which needs special treatment?
                # Better location is right after the assignment
                target_parent.args[target_row] = Expr(:block, target_parent.args[target_row], :($x = $call))
            end
            # Store replacement variable location
            push!(replacement_variable_location, (x, call_location_["parent"], call_location_["row"]))
        end
    end
    # Replace calls in current locations with the variable
    for (x, parent, row) in replacement_variable_location
        parent.args[row] = :($x)
    end
    @show expression
end
