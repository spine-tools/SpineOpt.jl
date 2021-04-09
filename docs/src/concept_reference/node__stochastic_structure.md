The [node\_\_stochastic\_structure](@ref) relationship defines which [stochastic\_structure](@ref) the [node](@ref) uses.
Essentially, it sets the [stochastic\_structure](@ref) of all the `flow` [variables](@ref Variables) connected
to the [node](@ref), as well as the potential `node_state` [variable](@ref Variables).
Note that only one [stochastic\_structure](@ref) can be defined per [node](@ref) per [model](@ref),
as interpreted based on the [node\_\_stochastic\_structure](@ref) and [model\_\_stochastic\_structure](@ref)
relationships.
Investment [variables](@ref Variables) use dedicated relationships, as detailed in the [Investment Optimization](@ref) section.