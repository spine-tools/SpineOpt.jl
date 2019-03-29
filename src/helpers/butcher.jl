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
    expression = esc(expression)
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
            if arg isa Expr
                if arg.head == :kw
                    push!(call_arg_arr, arg.args[end])
                elseif arg.head == :parameters
                    append!(call_arg_arr, [x.args[end] for x in arg.args])
                elseif arg.head == :tuple
                    append!(call_arg_arr, arg.args)
                else
                    push!(call_arg_arr, arg)
                end
            else
                push!(call_arg_arr, arg)
            end
        end
        # Get rid of immutable arguments
        call_arg_arr = [x for x in call_arg_arr if !isimmutable(x)]
        isempty(call_arg_arr) && continue
        # Only keep going if all arguments are now Symbols
        all([x isa Symbol for x in call_arg_arr]) || continue
        # Find top-most node where all arguments are assigned
        topmost_node_id = maximum(
            if haskey(assignment_location, arg)
                minimum(location["node_id"] for location in assignment_location[arg])
            else
                0
            end
            for arg in call_arg_arr
        )
        # Build dictionary of places where arguments are reassigned
        # below the top-most node
        arg_assignment_location = Dict()
        for arg in call_arg_arr
            for location in get(assignment_location, arg, [])
                location["node_id"] < topmost_node_id && continue
                push!(arg_assignment_location, location["node_id"] => (location["parent"], location["row"]))
            end
        end
        # Find better place for the call
        for call_location in call_location_arr
            # Make sure we use the most recent value of all the arguments (take maximum)
            target_node_id = try
                maximum(x for x in keys(arg_assignment_location) if x < call_location["node_id"])
            catch ArgumentsError
                # One or more arguments are not assigned before the call is made, not our fault, will blow up
                continue
            end
            target_parent, target_row = arg_assignment_location[target_node_id]
            # Only relocate if we have a recipe for it (see for loop right below this one)
            !in(target_parent.head, (:for, :while, :block)) && continue
            # Don't relocate recursive assignment, e.g., x = f(x)
            target_parent.args[target_row].args[end] == call && continue
            # Create or retrieve replacement variable
            x = get!(replacement_variable, target_node_id, gensym())
            # Add new call_location for the replacement variable
            push!(replacement_variable_location, (x, call_location["parent"], call_location["row"]))
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
 2. Register the location of calls and iteration specs into the supplied dictionaries.
"""
function beat(
        node::Any, node_id::Int64, parent::Any, row::Int64,
        call_location::Dict{Expr,Array{Dict{String,Any},1}},
        assignment_location = Dict{Symbol,Array{Dict{String,Any},1}})
    !isa(node, Expr) && return
    if node.head == :call
    end
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
        variable_arr = if isa(node.args[1], Symbol)
            # Single assignment, e.g., a = 1
            [node.args[1]]
        elseif isa(node.args[1], Expr) && node.args[1].head == :tuple
            # Multiple tuple assignment
            node.args[1].args
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
