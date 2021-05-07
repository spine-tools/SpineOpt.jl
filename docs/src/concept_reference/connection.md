A [connection](@ref) represents a transfer of one [commodity](@ref) over space.
For example, an electricity transmission line, a gas pipe, a river branch,
can be modelled using a [connection](@ref).

A [connection](@ref) always takes [commodities](@ref commodity) from one or more [node](@ref)s, and releases them to
one or more (possibly the same) [node](@ref)s.
The former are specificed through the [connection\_\_from\_node](@ref) relationship,
and the latter through [connection\_\_to\_node](@ref).
Every [connection](@ref) inherits the temporal and stochastic structures from the associated nodes.
The model will generate `connection_flow` variables for every combination of
[connection](@ref), [node](@ref), *direction* (from node or to node), *time slice*, and *stochastic scenario*,
according to the above relationships.

The operation of the [connection](@ref) is specified through a number of parameter values.
For example, the capacity of the connection, as the maximum amount of energy that can enter or leave it,
is given by [connection\_capacity](@ref).
The conversion ratio of input to output can be specified using any of [fix\_ratio\_out\_in\_connection\_flow](@ref),
[max\_ratio\_out\_in\_connection\_flow](@ref), and [min\_ratio\_out\_in\_connection\_flow](@ref) parameters
in the [connection\_\_node\_\_node](@ref) relationship.
The delay on a connection, as the time it takes for the energy to go from one end to the other,
is given by [connection\_flow\_delay](@ref).