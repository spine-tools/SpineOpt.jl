The definition of the `min_down_time` parameter will trigger the creation of the [Constraint on minimum downtime](@ref constraint_min_down_time). It sets a lower bound on the period that a unit has to stay offline after a shutdown.

It can be defined for a [unit](@ref) and will then impose restrictions on the [units\_on](@ref var_units_on) variables that represent the on- or offline status of the unit. The parameter is given as a duration value. When the parameter is not included, the aforementioned constraint will not be created, which is equivalent to choosing a value of 0.

For a more complete description of unit commitment restrictions, see [Unit commitment](@ref).
