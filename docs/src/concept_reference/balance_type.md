The [balance\_type](@ref) parameter determines whether or not a [node](@ref) needs to be balanced,
in the classical sense that the sum of flows entering the [node](@ref) is equal to the sum of flows
leaving it.

The values `balance_type_node` (the default) and `balance_type_group` mean that the [node](@ref) is always balanced.
The only exception is if the [node](@ref) belongs in a group that has itself [balance\_type](@ref) equal to
`balance_type_group`.
The value `balance_type_none` means that the [node](@ref) doesn't need to be balanced.
