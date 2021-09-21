The [unit\_flow\_coefficient](@ref) is an optional parameter that can be used to include the [unit\_flow](@ref) or [unit\_flow\_op](@ref)
variables from or to a [node](@ref) in a [user\_constraint](@ref) via the
[unit\_\_from\_node\_\_user\_constraint](@ref) and [unit\_\_to\_node\_\_user\_constraint](@ref) relationships.
Essentially, [unit\_flow\_coefficient](@ref) appears as a coefficient for the
[unit\_flow](@ref) and [unit\_flow\_op](@ref) variables from or to the [node](@ref)
in the [user constraint](@ref constraint_user_constraint).

Note that the [unit\_flow\_op](@ref) variables are a bit of a special case,
defined using the [operating\_points](@ref) parameter.
