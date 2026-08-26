Used to constrain the upper and lower bounds of the [unit\_flow](@ref var_unit_flow) variables
based on the values in the previous solve in a rolling problem (see [Rolling horizon tutorial](@ref)),
up to [unit\_flow\_non\_anticipativity\_time](@ref).
Effectively, if [unit\_flow](@ref var_units_on) is within [unit\_flow\_non\_anticipativity\_time](@ref)
of the start of the current window,
its values are constrained to its previous values plus/minus [unit\_flow\_non\_anticipativity\_margin](@ref).

See also [units\_on\_non\_anticipativity\_time](@ref),
[units\_on\_non\_anticipativity\_margin](@ref).