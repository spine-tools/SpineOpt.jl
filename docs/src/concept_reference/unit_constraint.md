The [unit\_constraint](@ref) is a generic data-driven [custom constraint](@ref constraint_unit_constraint),
which allows for defining constraints involving multiple [unit](@ref)s, [node](@ref)s, or [connection](@ref)s.
The [constraint\_sense](@ref) parameter changes the sense of the [unit\_constraint](@ref),
while the [right\_hand\_side](@ref) parameter allows for defining the constant terms of the constraint.

Coefficients for the different [variables](@ref Variables) appearing in the [unit\_constraint](@ref) are defined
using relationships, like e.g. [unit\_\_from\_node\_\_unit\_constraint](@ref) and
[connection\_\_to\_node\_\_unit\_constraint](@ref) for [unit\_flow](@ref) and [connection\_flow](@ref) variables,
or [unit\_\_unit\_constraint](@ref) and [node\_\_unit\_constraint](@ref) for [units\_on](@ref), [units\_started\_up](@ref),
and [node_state](@ref) variables.
