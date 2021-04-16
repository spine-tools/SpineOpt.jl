The [unit\_flow\_coefficient](@ref) is an optional parameter that can be used to include the `unit_flow` or `unit_flow_op`
[variables](@ref Variables) from or to a [node](@ref) in a [unit\_constraint](@ref) via the
[unit\_\_from\_node\_\_unit\_constraint](@ref) and [unit\_\_to\_node\_\_unit\_constraint](@ref) relationships.
Essentially, [unit\_flow\_coefficient](@ref) appears as a coefficient for the
`unit_flow` and `unit_flow_op` [variables](@ref Variables) from or to the [node](@ref)
in the [unit constraint](@ref constraint_unit_constraint).

Note that the `unit_flow_op` [variables](@ref Variables) are a bit of a special case,
defined using the [operating\_points](@ref) parameter.
