The [node\_\_stochastic\_structure](@ref) relationship defines which [stochastic\_structure](@ref) the [node](@ref) uses.
Essentially, it sets the [stochastic\_structure](@ref) of all the [unit\_flow](@ref var_unit_flow) and
[connection\_flow](@ref var_connection_flow) variables connected to the [node](@ref),
as well as the potential [node\_state](@ref var_node_state) variable.
Note that only one [stochastic\_structure](@ref) can be defined per [node](@ref) per [model](@ref),
as interpreted based on the [node\_\_stochastic\_structure](@ref) relationship.
Investment [variables](@ref Variables) use dedicated relationships, as detailed in the [Investment Optimization](@ref) section.

The [node\_\_stochastic\_structure](@ref) relationship uses the [model\_\_default\_stochastic\_structure](@ref)
relationship if not specified.
