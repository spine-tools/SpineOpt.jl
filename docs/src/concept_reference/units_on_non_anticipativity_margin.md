Used to constrain the upper and lower bounds of the [units\_on](@ref var_units_on) variable
based on the values in the previous solve in a rolling problem (see [Rolling horizon tutorial](@ref)),
up to [units\_on\_non\_anticipativity\_time](@ref).
Effectively, if [units\_on](@ref var_units_on) is within [units\_on\_non\_anticipativity\_time](@ref)
of the start of the current window,
its values are constrained to its previous values plus/minus [units\_on\_non\_anticipativity\_margin](@ref).

See also [unit\_flow\_non\_anticipativity\_time](@ref)
[unit\_flow\_non\_anticipativity\_margin](@ref).