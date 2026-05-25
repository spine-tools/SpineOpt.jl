`online_variable_type` is a method parameter to model the 'commitment' or 'activation' of a [unit](@ref),
that is the situation where the unit becomes online and active in the system. It can take the values "unit\_online\_variable\_type\_binary", "unit\_online\_variable\_type\_integer", "unit\_online\_variable\_type\_linear" and "unit\_online\_variable\_type\_none".

If `unit_online_variable_type_binary`, then the commitment is modelled as an online/offline decision (classic unit commitment).

If `unit_online_variable_type_integer`, then the commitment is modelled as the number of units that are online (clustered unit commitment). 

If `unit_online_variable_type_linear`, then the commitment is modelled as the number of units that are online, but here it is also possible to activate 'fractions' of a unit. This should reduce computational burden compared to `unit_online_variable_type_integer`.

If `unit_online_variable_type_none`, then the committment is not modelled at all and the unit is assumed to be always online. This reduces the computational burden the most.
