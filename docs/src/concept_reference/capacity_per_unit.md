To set an upper bound on the commodity flow of a unit in a certain direction,
the [capacity\_per\_unit](@ref) constraint needs to be defined on a [unit\_\_to\_node](@ref)
or [node\_\_to\_unit](@ref) relationship. By defining the parameter, the [unit\_flow](@ref) variables
to or from a [node](@ref) or a group of nodes will be constrained by the [capacity constraint](@ref constraint_unit_flow_capacity).

Note that if the [capacity\_per\_unit](@ref) parameter is defined on a node group, the sum of all [unit\_flow](@ref)s
within the specified node group will be constrained by the [capacity\_per\_unit](@ref).
