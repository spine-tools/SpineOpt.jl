The [node\_type](@ref) parameter determines whether or not a [node](@ref) needs to be balanced,
in the classical sense that the sum of flows entering the [node](@ref) is equal to the sum of flows
leaving it, and whether the [node](@ref) has a storage state that can increase and decrease based on the
flows entering and leaving the [node](@ref).

The values `balance_node` (the default) and `balance_group` mean that the [node](@ref) is always balanced according 
to the [nodal balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints.

The values `storage_node` and `storage_group` mean that the [node](@ref) is always balanced, but
the [node](@ref) has a [node\_state](@ref) variable generated for it that can increase and decrease based on the
flows entering and leaving the [node](@ref), allowing for [commodity](@ref) storage at the [node](@ref).
Note that you'll also have to specify a value for the [state_coeff](@ref) parameter,
as otherwise the [node\_state](@ref) variable has zero [commodity](@ref) capacity.

The only exceptions to enforcing the balance in the options above are if the [node](@ref) belongs in a group that has
itself [node\_type](@ref) equal to `balance_group` or `storage_group`.

The value `no_balance` means that the [node](@ref) doesn't need to be balanced.