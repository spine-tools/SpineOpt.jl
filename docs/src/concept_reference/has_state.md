The [has\_state](@ref) parameter is simply a `Bool` flag for whether a [node](@ref) has a [node\_state](@ref) variable.
By default, it is set to `false`, so the [node](@ref)s enforce instantaneous [commodity](@ref) balance
according to the [nodal balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints.
If set to `true`, the [node](@ref) will have a [node\_state](@ref) variable generated for it,
allowing for [commodity](@ref) storage at the [node](@ref).
Note that you'll also have to specify a value for the [state_coeff](@ref) parameter,
as otherwise the [node\_state](@ref) variable has zero [commodity](@ref) capacity.
