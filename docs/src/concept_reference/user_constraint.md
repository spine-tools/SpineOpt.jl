The [user\_constraint](@ref) is a generic data-driven [custom constraint](@ref constraint_user_constraint),
which allows for defining constraints involving multiple [unit](@ref)s, [node](@ref)s, or [connection](@ref)s.
The [constraint\_sense](@ref) parameter changes the sense of the [user\_constraint](@ref),
while the [right\_hand\_side](@ref) parameter allows for defining the constant terms of the constraint.

Coefficients for the different [variables](@ref Variables) appearing in the [user\_constraint](@ref) are defined
using relationships, like e.g. [unit\_flow\_\_user\_constraint](@ref) and
[connection\_\_to\_node\_\_user\_constraint](@ref) for [unit\_flow](@ref var_unit_flow) and [connection\_flow](@ref var_connection_flow) variables,
or [unit\_\_user\_constraint](@ref) and [node\_\_user\_constraint](@ref) for [units\_on](@ref var_units_on), [units\_started\_up](@ref var_units_started_up),
and [node\_state](@ref var_node_state) variables.

For more information, see the dedicated article on [User Constraints](@ref)
