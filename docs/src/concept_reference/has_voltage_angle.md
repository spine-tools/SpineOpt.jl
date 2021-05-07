For the use of node-based lossless DC powerflow, each node will be associated with
a [node\_voltage\_angle](@ref) variable. To enable the generation
of the variable in the optimization model, the boolean parameter
[has\_voltage\_angle](@ref) should be set true.
The voltage angle at a certain node can also be constrained through the
parameters [max\_voltage\_angle](@ref) and [min\_voltage\_angle](@ref). More details on the use of  lossless nodal DC power flows
are described [here](@ref Lossless-nodal-DC-power-flows)
