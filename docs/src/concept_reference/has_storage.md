The [has\_storage](@ref) parameter determines whether the [node](@ref) has a [node\_state](@ref) variable generated for 
it that can increase and decrease based on the flows entering and leaving the [node](@ref), allowing for commodity 
storage at the [node](@ref).

The default value is `false`, meaning that the node cannot store the commodity. Define the value as `true` to allow for commodity storage.

Note that you'll also have to specify a value for the [storage_state_coefficient](@ref) parameter,
as otherwise the [node\_state](@ref) variable has zero commodity capacity.