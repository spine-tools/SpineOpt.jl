A [unit](@ref) represents an energy conversion process, where energy of one [commodity](@ref) can be converted
into energy of another [commodity](@ref). For example, a gas turbine, a power plant, or even a load,
can be modelled using a [unit](@ref).

A [unit](@ref) always takes energy from one or more [node](@ref)s, and releases energy to
one or more (possibly the same) [node](@ref)s.
The former are specificed through the [unit\_\_from\_node](@ref) relationship,
and the latter through [unit\_\_to\_node](@ref).
Every [unit](@ref) has a temporal and stochastic structures given by the
[units\_on\_\_temporal\_block](@ref) and [units\_on\_\_stochastic\_structure] relationships.
The model will generate `unit_flow` variables for every combination of
[unit](@ref), [node](@ref), *direction* (from node or to node), *time slice*, and *stochastic scenario*,
according to the above relationships.

The operation of the [unit](@ref) is specified through a number of parameter values.
For example, the capacity of the unit, as the maximum amount of energy that can enter or leave it,
is given by [unit\_capacity](@ref).
The conversion ratio of input to output can be specified using any of [fix\_ratio\_out\_in\_unit\_flow](@ref),
[max\_ratio\_out\_in\_unit\_flow](@ref), and [min\_ratio\_out\_in\_unit\_flow](@ref).
The variable operating cost is given by [vom\_cost](@ref).