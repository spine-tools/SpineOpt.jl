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


function push_recursive!(arr, expr)
    if expr isa Expr
        if expr.head == :kw
            push_recursive!(arr, expr.args[end])
        elseif expr.head in (:parameters, :tuple)
            for x in expr.args
                push_recursive!(arr, x)
            end
        else
            push!(arr, expr)
        end
    else
        push!(arr, expr)
    end
end

"""
    @butcher expression

Butcher an expression so that method calls involving iteration variables
are performed as soon as those variables are specified. Needs testing.

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
    replacement_variable_location = Array{Any,1}()
    # 'Beat' each node in the expression tree (see definition of `beat` below)
    visit_node(expression, 1, nothing, 1, beat, call_location, assignment_location)
    for (call, call_location_arr) in call_location
        call_arg_arr = []  # Array of all arguments
        replacement_variable = Dict()  # Variable to store the return value of each relocated call
        # Build array of arguments without keywords
        for arg in call.args[2:end]  # First arg is the method name
            push_recursive!(call_arg_arr, arg)
        end
        # Get rid of immutable arguments
        call_arg_arr = [arg for arg in call_arg_arr if !isimmutable(arg)]
        isempty(call_arg_arr) && continue
        # Only keep going if all arguments are now Symbols
        all([arg isa Symbol for arg in call_arg_arr]) || continue
        # Only keep going if we know where all args are assigned
        all([haskey(assignment_location, arg) for arg in call_arg_arr]) || continue
        # Find top-most node where all arguments are assigned
        topmost_node_id = maximum(
            minimum(location["node_id"] for location in assignment_location[arg]) for arg in call_arg_arr
        )
        # Build dictionary of places where arguments are reassigned below the top-most node
        arg_assignment_location = Dict(
            loc["node_id"] => (loc["parent"], loc["row"])
            for arg in call_arg_arr for loc in assignment_location[arg] if loc["node_id"] >= topmost_node_id
        )
        # Find better place for the call
        for call_location in call_location_arr
            # Check that all args are defined at least once before the call
            assignment_location_arr = [x for x in keys(arg_assignment_location) if x < call_location["node_id"]]
            isempty(assignment_location_arr) && continue
            # Make sure we use the most recent value of all the arguments (take maximum)
            node_id = maximum(assignment_location_arr)
            # parent, row = arg_assignment_location[node_id]
            # Create or retrieve replacement variable
            x = get!(replacement_variable, node_id, gensym())
            # Add new call_location for the replacement variable
            push!(replacement_variable_location, (x, call, call_arg_arr, call_location["parent"], call_location["row"]))
        end
        # Put the call at a better location, assign result to replacement variable
        for (node_id, x) in replacement_variable
            ex = quote
                # Catch exceptions, so we can throw them when the variable gets actually instantiated
                $x = try
                    $call
                catch err
                    err
                end
                # Store the result together with the argument values in a Replacement object
                $x = SpineModel.Replacement($x, [$(call_arg_arr...)])
            end
            parent, row = arg_assignment_location[node_id]
            parent.args[row + 1] = Expr(:block, ex, parent.args[row + 1])
        end
    end
    # Replace calls in original locations with the replacement variable
    for (x, call, call_arg_arr, parent, row) in replacement_variable_location
        parent.args[row] = quote
            # Check if the argument values are the same as we stored in the Replacement
            if $(x).args == [$(call_arg_arr...)]
                # Throw exception or return actual value
                if $(x).val isa Exception
                    throw($(x).val)
                else
                    $(x).val
                end
            else
                # Call the function again
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
