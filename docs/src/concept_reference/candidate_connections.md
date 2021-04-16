The [candidate\_connections](@ref) parameter denotes the possibility of investing on a certain [connection](@ref).

The default value of `nothing` means that the [connection](@ref) can't be invested in, because it's already in operation.
An integer value represents the maximum investment possible at any point in time, as a factor of the [connection\_capacity](@ref).

In other words, [candidate\_connections](@ref) is the upper bound of the [connections\_invested\_available](@ref) variable.
