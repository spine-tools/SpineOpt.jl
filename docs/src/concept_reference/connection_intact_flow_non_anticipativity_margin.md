Used to constrain the upper and lower bounds of the [connection\_intact\_flow](@ref var_connection_intact_flow) variables
based on the values in the previous solve in a rolling problem (see [Rolling horizon tutorial](@ref)),
up to [connection\_intact\_flow\_non\_anticipativity\_time](@ref).
Effectively, if [connection\_intact\_flow](@ref var_connection_intact_flow) is within [connection\_intact\_flow\_non\_anticipativity\_time](@ref)
of the start of the current window,
its values are constrained to its previous values plus/minus [connection\_intact\_flow\_non\_anticipativity\_margin](@ref).