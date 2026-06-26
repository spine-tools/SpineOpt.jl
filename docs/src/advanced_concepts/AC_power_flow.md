# Radial AC power flows

SpineOpt includes single-phase equivalent AC optimal power flow (OPF) calculation. It is suitable for planning studies and simulating balanced power flow in different operational situations.


## Defining the problem for AC flow calculation

### Power lines

In the following, it is described how to set up a connection in order to represent an overhead line or cable. 

**[connection](@ref)**: A connection represents the electricity line being modelled. As usual, one has to define the relationships **[connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)** : These relationships need to be introduced between the connection and each node. The connection should be unidirectional, in other words there should only be connection\_\_from\_node or connection\_\_to\_node relationship between a node and a connection.

**[connection\_\_node\_\_node](@ref)**: This relationship should be defined so that the first node is the source bus and second node the destination bus. N.B. Do not manually fix an efficiency for the line (such as via a [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter).
   
A Π model with shunt susceptance is used for lines. The physical properties include the series reactance, represented by the parameter [connection\_reactance](@ref), series resistance represented by the parameter [connection\_resistance](@ref). It is recommended that these parameters are given in a p.u.

Furthermore, a capacity limit on the connection line can be introduced on these relationships through the parameter [connection\_capacity](@ref).

### Buses

 In a AC power flow model, **[node](@ref)** corresponds to a bus. For AC buses the parameter [has\_voltage](@ref) needs to be `true`. Limits on the bus voltage magnitude can be enforced through the [max\_voltage](@ref) and min\_voltage parameters.

### Units

In a AC power flow model, units can produce both active and reactive power. Reactive power capability is automatically triggered if the unit is connected
via relationship to a node where [has\_voltage](@ref) has been set to `true`. Units can also absorb reactive power.

It is recommended that the parameter [vom\_cost\_reactive](@ref) be set to a positive value. Otherwise the relaxed conic constraint may not become binding.

### Investments

Power flow is governed by the impedance parameters given for a specific line. The model formulation does not allow adjusting the line sizing within the model. However, the model can include binary investment decisions (go/no-go). Thus [connection\_investment\_variable\_type](@ref) needs to be set to `variable_type_integer`. [connection\_capacity](@ref) should be set to a value which is at least as large as the estimated power carrying capacity of the candidate line. See [the chapter about investment optimization](@ref Investment-Optimization) for the other parameters and relationships you need to set to activate investments.

## Results

the [node\_voltage\_squared](@ref) variable

## Formulations

Currently, there are three formulations for the AC OPF. In decreasing order of accuracy these are:

- Second order cone programming (SOCP) relaxation of optimal power flow problem in rectangular coordinates. 
- Linear approximation of the SOCP relaxation
- Lindistflow lossless formulation

Selection of the formulation takes place by the model-wide parameter [ac\_opf\_model\_formulation](@ref). The default is the linear approximation of the SOCP relaxation. All formulations are suitable only for radial networks, which are typically found in distribution grids. If loops are present in the network, solution will be returned but the results will not be correct. 


## Creating an Example  


