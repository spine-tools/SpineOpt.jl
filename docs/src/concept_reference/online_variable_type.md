`online_variable_type` is a method parameter to model the 'commitment' or 'activation' of a [unit](@ref),
that is the situation where the unit becomes online and active in the system. It can take the values "binary", "integer", "linear" and "none".

If `binary`, then the commitment is modelled as an online/offline decision (classic unit commitment).

If `integer`, then the commitment is modelled as the number of units that are online (clustered unit commitment). 

If `linear`, then the commitment is modelled as the number of units that are online, but here it is also possible to activate 'fractions' of a unit. This should reduce computational burden compared to `integer`.

If `none`, then the committment is not modelled at all and the unit is assumed to be always online. This reduces the computational burden the most.
