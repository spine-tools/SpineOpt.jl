`node__user_constraint` is a two-dimensional relationship between a [node](@ref) and a [user_constraint](@ref). The relationship specifies that a variable associated only with the node (currently only the `node_state`) is involved in the constraint. For example, the [node\_state\_coefficient](@ref) defined on `node__user_constraint` specifies the coefficient of the [node](@ref)'s `node_state` variable in the specified [user_constraint](@ref).

See also [user_constraint](@ref)
