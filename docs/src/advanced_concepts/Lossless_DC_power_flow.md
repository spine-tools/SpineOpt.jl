# Lossless nodal DC power flows

Currently, there are two different methods to represent lossless DC power flows. In the following the implementation of the nodal model is presented, based of node voltage angles.

## [Key concepts](@id key-concepts-advanced-nodal-DC)
In the following, it is described how to set up a connection in order to represent a nodal lossless DC power flow network. Therefore, key object - and relationship classes as well as parameters are introduced.

1. **[connection](@ref)**: A connection represents the electricity line being modelled. A physical property of a connection is its [connection\_reactance](@ref), which is defined on the connection object. Furthermore, if the reactance is given in a p.u. different from the standard unit used (e.g. p.u. = 100MVA), the parameter [connection\_reactance\_base](@ref) can be used to perform this conversion.
2. **[node](@ref)**: In a lossless DC power flow model, nodes correspond to buses. To use voltage angles for the representation of a lossless DC model, the [has\_voltage\_angle](@ref) needs to be `true` for these nodes (which will trigger the generation of the [node\_voltage\_angle](@ref) variable). Limits on the voltage angle can be enforced through the [max\_voltage\_angle](@ref) and [min\_voltage\_angle](@ref) parameters. The reference node of the system should have a voltage angle equal to zero, assigned through the parameter [fix\_node\_voltage\_angle](@ref).
3. **[connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)** : These relationships need to be introduced between the connection and each node, in order to allow power flows (i.e. [connection\_flow](@ref)). Furthermore, a capacity limit on the connection line can be introduced on these relationships through the parameter [connection\_capacity](@ref).
4. **[connection\_\_node\_\_node](@ref)**: To ensure energy conservation across the power line, a fixed ratio between incoming and outgoing flows should be given. The [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter enforces a fixed ratio between outgoing flows (i.e. to\_node) and incoming flows (i.e. from\_node). This parameter should be defined for both flow direction.

The mathematical formulation of the lossless DC power flow model using voltage angles is fully described [here](@ref nodal-lossless-DC).
