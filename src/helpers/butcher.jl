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

struct Replacement
    val
    args::Array
end


"""
    push_recursive!(arr, arg)

Visit the given argument expression and add all symbols to the end of the array.
"""
function push_recursive!(arr, arg)
    if arg isa Expr
        if arg.head == :kw
            push_recursive!(arr, arg.args[end])
        elseif arg.head in (:parameters, :tuple)
            for x in arg.args
                push_recursive!(arr, x)
            end
        else
            push!(arr, arg)
        end
    else
        push!(arr, arg)
    end
end

"""
    append_recursive!(arr, arg_arr)

Sweep the given array of call argument expressions and add all symbols to the end of the array.
"""
function append_recursive!(arr, arg_arr)
    if arg_arr[1] isa Expr && expr_arr[1].head == :call
        append_recursive!(arr, arg_arr[1].args)
    end
    for arg in arg_arr[2:end]
        push_recursive!(arr, arg)
    end
end

"""
    @butcher expression

An equivalent expression where method calls involving iteration variables
are performed as soon as those variables are specified. Use with care.

For instance, an expression like this:

```
for i=1:10
    for j=1:1e12
        y = f(i)
        ...
    end
end
```

is turned into something like this:

```
for i=1:10
    ret = f(i)
    for j=1:1e12
        y = ret
        ...
    end
end
```

This is mainly intended to improve performance in cases where the implementation
of a method is expensive, but for readability reasons the programmer wants to call it
at unconvenient places -such as the body of a long inner for loop.
"""
macro butcher(expression)
    expression = macroexpand(@__MODULE__, esc(expression))
    call_location = Dict{Expr,Array{Dict{String,Any},1}}()
    assignment_location = Dict{Symbol,Array{Dict{String,Any},1}}()
    replacement_variable = Dict{Int64,Array{Any,1}}()
    replacement_variable_location = Array{Any,1}()
    # 'Beat' each node in the expression tree (see definition of `beat` below)
    visit_node(expression, 1, nothing, 1, beat, call_location, assignment_location)
    for (call, call_location_arr) in call_location
        call_replacement_variable = Dict()  # node_id => Replacement object
        # Build array of arguments without keywords
        call_arg_arr = []
        append_recursive!(call_arg_arr, call.args)
        # Get rid of immutable arguments
        call_arg_arr = [arg for arg in call_arg_arr if !isimmutable(arg)]
        isempty(call_arg_arr) && continue
        # Only keep going if all arguments are now Symbols
        all([arg isa Symbol for arg in call_arg_arr]) || continue
        # Only keep going if we know where all args are assigned
        all([haskey(assignment_location, arg) for arg in call_arg_arr]) || continue
        # Find first node where all arguments are assigned
        base_node_id = maximum(
            minimum(location["node_id"] for location in assignment_location[arg]) for arg in call_arg_arr
        )
        # Build dictionary of places where any arguments are reassigned after the base node
        arg_assignment_location = Dict(
            loc["node_id"] => (loc["parent"], loc["row"])
            for arg in call_arg_arr for loc in assignment_location[arg] if loc["node_id"] >= base_node_id
        )
        for call_location in call_location_arr
            # Build array of nodes where all arguments are assigned before the call
            assignment_location_arr = [x for x in keys(arg_assignment_location) if x < call_location["node_id"]]
            # Only keep going if at least one of such nodes exists
            isempty(assignment_location_arr) && continue
            # Use the most recent value of all the arguments
            node_id = maximum(assignment_location_arr)
            # Create or retrieve replacement variable
            x = get!(call_replacement_variable, node_id, gensym())
            # Add new call_location for the replacement variable
            push!(
                replacement_variable_location,
                (x, call, call_arg_arr, call_location["parent"], call_location["row"]))
        end
        for (node_id, x) in call_replacement_variable
            parent, row = arg_assignment_location[node_id]
            x_arr = get!(replacement_variable, node_id, Array{Any,1}())
            push!(x_arr, (x, call, call_arg_arr, parent, row))
        end
    end
    for (node_id, x_arr) in replacement_variable
        for (x, call, call_arg_arr, parent, row) in reverse(x_arr)
            # Create replacement expression
            y = gensym()
            ex = quote
                # Catch exceptions, so we can throw them when the variable gets actually instantiated
                $y = try
                    $call
                catch err
                    err
                end
                # Store the result together with the argument values in a Replacement object
                $x = SpineModel.Replacement($y, [$(call_arg_arr...)])
            end
            # Put the above expression at the desired location
            parent.args[row + 1] = Expr(:block, ex, parent.args[row + 1])
        end
    end
    for (x, call, call_arg_arr, parent, row) in replacement_variable_location
        # Replace calls in original locations with the replacement expression
        parent.args[row] = quote
            # Check if the argument values are the same as the ones stored in the Replacement object
            if $(x).args == [$(call_arg_arr...)]
                if $(x).val isa Exception
                    # Throw stored exception
                    throw($(x).val)
                else
                    # Return stored value
                    $(x).val
                end
            else
                # Argument values don't match, call the function again
                $call
            end
        end
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
 2. Register the location of calls and iteration specs into the supplied dictionaries.
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
    # Register location (node_id, parent and row) of iteration spec
    elseif node.head == :(=) && parent.head == :for
        var = node.args[1]
        variable_arr = if isa(var, Symbol)
            # Single assignment, e.g., for a = 1:10
            [var]
        elseif isa(var, Expr) && var.head == :tuple
            # Multiple tuple assignment, e.g, for (k, v) in pairs
            var.args
        else
            # Not handled
            []
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
    node_id += 1
    if node isa Expr && checkbounds(Bool, node.args, 1)
        child = node.args[1]
        node_id = visit_node(child, node_id, node, 1, func, func_args...; func_kwargs...)
    end
    if parent isa Expr && checkbounds(Bool, parent.args, row + 1)
        sibling = parent.args[row + 1]
        node_id = visit_node(sibling, node_id, parent, row + 1, func, func_args...; func_kwargs...)
    end
    node_id
end
