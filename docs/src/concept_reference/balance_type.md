The [balance\_type](@ref) parameter determines whether or not a [node](@ref) needs to be balanced,
in the classical sense that the sum of flows entering the [node](@ref) is equal to the sum of flows
leaving it.

The values `node_balance` (the default) and `group_balance` mean that the [node](@ref) is always balanced according 
to the [nodal balance](@ref constraint_nodal_balance) and [node injection](@ref constraint_node_injection) constraints.

The only exceptions to enforcing the balance in the options above are if the [node](@ref) belongs in a group that has
itself [balance\_type](@ref) equal to `group_balance`.

The value `none` means that the [node](@ref) doesn't need to be balanced.