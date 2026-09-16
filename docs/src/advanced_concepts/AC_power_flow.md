# Radial AC power flows

SpineOpt includes single-phase equivalent AC optimal power flow (OPF) calculation. It is suitable for planning studies and simulating balanced power flow in different operational situations. The AC power flow calculation is suitable for radial networks typical in distribution networks. It does not track the voltage phase angle across the network and thus the results for looped networks will not be correct.


## Defining the problem for AC flow calculation

### Power lines

In the following, it is described how to set up a connection in order to represent an overhead line or cable. 

**[connection](@ref)**: A connection represents the electricity line being modelled. As usual, one has to define the relationships **[connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)** : These relationships need to be introduced between the connection and each node. The connection should be unidirectional, in other words there should only be connection\_\_from\_node or connection\_\_to\_node relationship between a node and a connection. Also it is not recommended to define multiple routes for one connection object.

**[connection\_\_node\_\_node](@ref)**: This relationship should be defined so that the first node is the source bus and second node the destination bus. The [connection\_has\_ac\_flow](@ref) should be set true for this relationship to enable AC flow and indicate positive direction. N.B. Do not manually fix an efficiency for the line (such as via a [fix\_ratio\_out\_in\_connection\_flow](@ref) parameter).
   
A Π model with shunt susceptance is used for lines. The physical properties include the series reactance, represented by the parameter [reactance](@ref), series resistance represented by the parameter [resistance](@ref) and shunt susceptance by the parameter [line\_shunt\_susceptance](@ref). It is recommended that these parameters are given as per-unit values.


### Buses

In a AC power flow model, **[node](@ref)** corresponds to a bus. To enable the AC flow calculation, one or more **[grid](@ref)** objects whose parameter [physics\_type](@ref) is set to [acflow\_physics](@ref grid_physics_list) must be defined. The grid objects must be tied to nodes via [node\_\_grid](@ref) relationships. 

Limits on the bus voltage magnitude (stated as per-unit value) can be enforced through the [max\_voltage](@ref) and [min\_voltage](@ref) parameters. You cannot set limits on the voltage phase angle.

### Loads

There is no specific load component. Loads are given as parameters for buses. As usual, you can define a demand value via the [demand](@ref) parameter. This refers to real power demand. Reactive power demand can be defined via the [demand_reactive](@ref) parameter. It is recommended that these parameters are given as per-unit values. However, you can also define [power_base](@ref) for the bus, which allows you to give demand values in absolute units and keep other parameters as per-unit values.

### Generators

Generators are represented by SpineOpt [unit](@ref)s. In a AC power flow model, units can produce both active and reactive power. Units can also absorb reactive power. Reactive power capability is automatically triggered if the unit is connected
via [unit\_\_to\_node](@ref) or [node\_\_to\_unit](@ref) relationship to an AC enabled bus. 

It is recommended that the parameter [vom\_cost\_reactive](@ref) be set to a positive value. Otherwise the relaxed conic constraint may not become binding.

### Investments

Power flow is governed by the impedance parameters given for a specific line. The model formulation does not allow adjusting the line sizing within the model. However, the model can include binary investment decisions (go/no-go). Thus [investment\_variable\_type](@ref) needs to be set to `binary` or `integer`. [capacity\_per\_connection](@ref) should be set to a value which is at least as large as the estimated power carrying capacity of the candidate line. Parameter [investment\_count\_max\_cumulative](@ref) should be set to 1. See [the chapter about investment optimization](@ref Investment-Optimization) for the other parameters and relationships you need to set to activate investments.

## Results

The variable [node\_voltage\_squared](@ref var_node_voltage_squared) tells the squared voltage magnitude in a bus. The variable [connection\_flow](@ref var_connection_flow) tells the real power flow in a power line, measured in the positive direction (from source to destination bus). Similarly, the variable [connection\_flow\_reactive](@ref var_connection_flow_reactive) tells the reactive power flow in a power line. See [Managing output](@ref how-to-manage-output) about how to add outputs to the model.

## Formulations

Currently, there are three formulations for the AC OPF. In decreasing order of accuracy these are:

- Second order cone programming (SOCP) relaxation of optimal power flow problem in rectangular coordinates. 
- Linear approximation of the SOCP relaxation
- Lindistflow lossless formulation

Selection of the formulation takes place by the model-wide parameter [ac\_opf\_model\_formulation](@ref). The default is the linear approximation of the SOCP relaxation. All formulations are suitable only for radial networks, which are typically found in distribution grids. If loops are present in the network, solution will be returned but the results will not be correct. 


## Creating an Example  
If we have model that is not currently set up AC flow, we can take the following steps.
 - Create a grid object and set its [physics\_type](@ref) parameter to `acflow\_physics`.
 - Create two bus (node) objects, call them A and B
   - The nodes need to use the same temporal resolution. Assign them to the same temporal block via [node\_\_temporal\_block](@ref) relationship. For a more detailed description of how the temporal structure in SpineOpt can be created, see [Temporal Framework](@ref).
   - Make sure your model has a [stochastic\_structure](@ref) and it is connected to the model object by [model\_\_default\_stochastic\_structure](@ref). See [Stochastic Framework](@ref stochastic_framework) for details.
   - Add the nodes to the grid by two [node\_\_grid](@ref) relationships with nodes A and B as the nodes. 
 - Create a unit with [unit\_\_to\_node](@ref) relationship with bus A. For this relationship set
   - [vom\_cost\_reactive](@ref) to 1.0
   - [vom\_cost](@ref) to 10.0
 - Create a line (connection) object with the following relationships
   - [connection\_\_from\_node](@ref) with node A
   - [connection\_\_to\_node](@ref) with node B
   - [connection\_\_node\_\_node](@ref) with node A as the first node and node B as the second node
    - Set also parameter [connection\_has\_ac\_flow](@ref) for this relationship to true
  - Set for example the following parameters to the line itself:
    - [resistance](@ref) to 0.1
    - [reactance](@ref) to 0.05
  - Add a load to bus B. Suppose $cos(\phi)$ = 0.8 and real power is 0.1 p.u. In other words set for node B
    - [demand](@ref) to 0.1
    - [demand_reactive](@ref) to 0.075

## Model reference

### Parameters for AC flow calculation

| Parameter Name                 | Object Class List            | Description                                     |
|--------------------------------|------------------------------|-------------------------------------------------|
| [ac\_opf\_model\_formulation](@ref) | [model](@ref) | The type of model formulation used for AC flow simulation.
| [vom\_cost\_reactive](@ref) | [unit\_\_to\_node](@ref) and [node\_\_to\_unit](@ref) | The cost of injecting or absorbing reactive power to the bus or from the bus.
| [vom\_cost](@ref) | [unit\_\_to\_node](@ref) and [node\_\_to\_unit](@ref) | The cost of injecting or absorbing real power to the bus or from the bus.
| [resistance](@ref)  | [connection](@ref) | The per-unit resistance of the line.
| [reactance](@ref)  | [connection](@ref) | The per-unit reactance of the line.
| [line\_shunt\_susceptance](@ref)  | [connection](@ref) | The per-unit shunt susceptance of the line.
| [demand](@ref)  | [node](@ref) | The real power demand (p.u. unless you have set [power_base](@ref)).
| [demand_reactive](@ref)  | [node](@ref) | The reactive power demand.
| [power_base](@ref)  | [node](@ref) | The base power used if calculating with absolute demand values.