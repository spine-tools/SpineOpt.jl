While the relationships [unit\_\_to\_node](@ref) and [unit\_\_to\_node](@ref)
take care of the automatic generation of the [unit\_flow](@ref) variables,
the [unit\_\_node\_\_node](@ref) relationships hold the information how the different commodity flows
of a unit interact. Only through this relationship and the associated parameters, the topology of a unit, i.e.
which intakes lead to which products etc., becomes unambiguous.

In almost all cases, at least one of the `..._ratio_...` parameters will be defined, e.g. to set a fixed ratio between
outgoing and incoming commodity flows of unit (see also e.g. [fix\_ratio\_out\_in\_unit\_flow](@ref)). Note that the parameters can
also be defined on a relationship between groups of objects, e.g. to force a fixed ratio between a group of nodes. In the triggered constraints,
this will lead to an aggregation of the individual unit flows.
