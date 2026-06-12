[connection\_\_user\_constraint](@ref) is a two-dimensional relationship between a [connection](@ref) and a [user\_constraint](@ref).
The relationship specifies that a variable or variable(s) associated only with the [connection](@ref) (not a [connection\_flow](@ref var_connection_flow) for example) are involved in the constraint.
For example, the [coefficient\_for\_connections\_invested](@ref) defined on [connection\_\_user\_constraint](@ref) specifies the coefficient of the [connections\_invested](@ref var_connections_invested) variable in the specified [user\_constraint](@ref).

See also [user\_constraint](@ref).