The [unit\_\_to\_node](@ref) and [unit\_\_from\_node](@ref) unit relationships are core elements of SpineOpt.
For each [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref), a [unit\_flow](@ref) variable is automatically
added to the model, i.e.
a commodity flow of a unit *to* or *from* a specific node, respectively.

Various parameters can be defined on the [unit\_\_to\_node](@ref) relationship, in order to
constrain the associated unit flows. In most cases a [unit\_capacity](@ref) will be defined for
an upper bound on the commodity flows. Apart from that, ramping abilities of a unit can be
defined. For further details on ramps see [Ramping](@ref).

To associate costs with a certain commodity flow, cost terms, such as [fuel\_cost](@ref)s and [vom\_cost](@ref)s,
can be included for the [unit\_\_to\_node](@ref) relationship.

It is important to note, that the parameters associated with the [unit\_\_to\_node](@ref) can be defined either
for a specific [node](@ref), or for a group of nodes. Grouping nodes for the described parameters will result
in an aggregation of the unit flows for the triggered constraint, e.g. the definition of the [unit\_capacity](@ref)
on a group of nodes will result in an upper bound on the sum of all individual [unit\_flow](@ref)s.
