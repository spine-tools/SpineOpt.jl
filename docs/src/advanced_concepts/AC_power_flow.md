# Radial AC power flows

SpineOpt includes AC optimal power flow (OPF) calculation for single-phase lines. 

Currently, the AC power flow calculation is based on the second order cone programming (SOCP) relaxation of optimal power flow problem in rectangular coordinates. This method is suitable for radial networks, which are typically found in distribution grids. In the following the implementation of the model is presented.

## Key concepts

### Connections
Connections represent In the following, it is described how to set up a connection in order to represent an AC power flow network. 

1. **[connection](@ref)**: A connection represents the electricity line being modelled. A physical property of a connection is its [connection\_reactance](@ref), which is defined on the connection object. Furthermore, if the reactance is given in a p.u. different from the standard unit used (e.g. p.u. = 100MVA), the parameter [connection\_reactance\_base](@ref) can be used to perform this conversion.
2. **[node](@ref)**: In a lossless DC power flow model, nodes correspond to buses. To use voltage angles for the representation of a lossless DC model, the [has\_voltage](@ref) needs to be `true` for these nodes (which will trigger the generation of the [node\_voltage\_squared](@ref) variable). Limits on the voltage angle can be enforced through the [max\_voltage\_angle](@ref) and [min\_voltage\_angle](@ref) parameters.
3. **[connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)** : These relationships need to be introduced between the connection and each node, in order to allow power flows (i.e. [connection\_flow](@ref)). Furthermore, a capacity limit on the connection line can be introduced on these relationships through the parameter [connection\_capacity](@ref).
4. **[connection\_\_node\_\_node](@ref)**: Do not set a [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter.

## Creating an Example  

## SOCP and linear formulations

