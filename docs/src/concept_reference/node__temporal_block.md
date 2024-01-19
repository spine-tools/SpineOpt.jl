This relationship links a [node](@ref) to a [temporal_block](@ref) and as such it will determine which temporal block governs the temporal horizon and resolution of the variables associated with this node. Specifically, the [resolution](@ref) of the temporal block will directly imply the duration of the time slices for which both the [flow variables](@ref Variables) and their associated constraints are created.

For a more detailed description of how the temporal structure in SpineOpt can be created, see [Temporal Framework](@ref).
