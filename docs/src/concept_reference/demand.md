The [demand](@ref) parameter represents a "demand" or a "load" of a [commodity](@ref) on a [node](@ref).
It appears in the [node injection constraint](@ref constraint_node_injection),
with positive values interpreted as "demand" or "load" for the modelled system,
while negative values provide the system with "influx" or "gain".
When the node is part of a group, the [fractional\_demand](@ref) parameter can be used to split [demand](@ref) into fractions,
when desired. See also: [Introduction to groups of objects](@ref)

The [demand](@ref) parameter can also be included in custom [user\_constraint](@ref)s
using the [demand\_coefficient](@ref) parameter for the [node\_\_user\_constraint](@ref) relationship.
