The [node\_type](@ref) parameter determines whether or not a [node](@ref) needs to be balanced,
in the classical sense that the sum of flows entering the [node](@ref) is equal to the sum of flows
leaving it, and whether the [node](@ref) has a storage state that can increase and decrease based on the
flows entering and leaving the [node](@ref).

The values `balance_node` (the default) and `balance_group` mean that the [node](@ref) is always balanced.
The values `storage_node` and `storage_group` mean that the [node](@ref) is always balanced, but
the [node](@ref) has a storage state that can increase and decrease based on the
flows entering and leaving the [node](@ref).
The only exceptions are if the [node](@ref) belongs in a group that has itself [node\_type](@ref) equal to
`balance_group` or `storage_group`.
The value `no_balance` means that the [node](@ref) doesn't need to be balanced.
