# Constraints

## Balance constraint

In **SpineOpt** (nodes)[#node] are the place, where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together. The energy balance is enforced by the following constraint:

```math
\begin{aligned}
& node_{injection}(n,s,t) \\
& + \sum_{\substack{(conn,n',d_{in},s,t) \in ind(connection_{flow}): \\ d_{out} == :to\_node}}
 connection_{flow}(conn,n',d_{in},s,t)\\
& - \sum_{\substack{(conn,n',d_{out},s,t) \in ind(connection_{flow}): \\ d_{out} == :from\_node}}
 connection_{flow}(conn,n',d_{out},s,t)\\
% & + node_{slack\_pos}(n,s,t) \\
% & - node_{slack\_neg}(n,s,t) \\
& \{>=,==,<=\} \\
& 0 \\
& \forall (n,s,t) \in ind(node_{stochastic\_time})
\end{aligned}
```
TODO: remove node_slack position -> can be handled with an additional unit?\\
TODO: Explain node group/ "is internal" properly

The node injection itself represents all local production and consumption, represented by the sum of all $unit_{flows}$:

```math
\begin{aligned}
& node_{injection}(n,s,t) \\
& == \\
& + \sum_{\substack{(u,n',d_{in},s,t) \in ind(unit_{flow}): \\ d_{out} == :to\_node}}
 unit_{flow}(u,n',d_{in},s,t)\\
& - \sum_{\substack{(u,n',d_{out},s,t) \in ind(unit_{flow}): \\ d_{out} == :from\_node}}
 unit_{flow}(u,n',d_{out},s,t)\\
& - demand(n,s,t)\\
& \forall (n,s,t) \in ind(node_{stochastic\_time})
\end{aligned}
```

If a node is to represent a storage, the constraint translates to:

```math
\begin{aligned}
& node_{injection}(n,s,t) \\
& == \\
& (node_{state}(n, s, t\_before)\\
& - node_{state}(n, s, t) \cdot p_{state\_coeff}(n, t)) \\
&   \cdot \Delta(t\_after) \\
&  - node_{state}(n, s, t) \cdot p_{frac\_state\_loss}(n, t) \\
&  + \sum_{\substack{(n2,s,t) \in ind(node_{state}): \\ \exists diff\_coeff(n2,n)}}
node_{state}(n2,s,t)\\
& - \sum_{\substack{(n2,s,t) \in ind(node_{state}): \\ \exists diff\_coeff(n,n2)}}
node_{state}(n2,s,t)\\
& + \sum_{\substack{(u,n',d_{in},s,t) \in ind(unit_{flow}): \\ d_{out} == :to\_node}}
 unit_{flow}(u,n',d_{in},s,t)\\
& - \sum_{\substack{(u,n',d_{out},s,t) \in ind(unit_{flow}): \\ d_{out} == :from\_node}}
 unit_{flow}(u,n',d_{out},s,t)\\
& - demand(n,s,t)\\
& \forall (n,s,t) \in ind(node_{stochastic\_time})
\end{aligned}
```

node state capacity:

## Unit operation

### Static constraints

#### Conversion constraint / limiting flow shares inprocess / relationship in process

Between the different flows, relationships can be imposed.
The most simple relationship is a linear relationship between input and output nodes/node groups (similar to TIMES EQ PTRANS).
Whenever there is only a single input node and a single output node, this relationship relates to the notion of an efficiency.
This equation can for instance also be used to relate emissions to input primary fuel flows.
In the most general form of the equation, two node groups are defined (an input node group $ng_{in}$ and an output node group $ng_{out}$),
and a linear relationship is expressed between both node groups. Note that whenever the relationship is specified between groups of multiple nodes,
there remains a degree of freedom regarding the composition of the input node flows within group $ng_{in}$  and the output node flows within group $ng_{out}$.

##### Fixed ratio between output and input `unit_flow`s: Parameter `fix_ratio_out_in_unit_flow(unit__node__node= u, ng_out, ng_in)`

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out}) \in ind(unit_{flow}): \\ (u,n,d,t_{out}) \, \in \, (u,ng_{out},:from\_node,t)}} unit_{flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& == p_{fix\_ratio\_out\_in\_unit_{flow}}(u,ng_{out},ng_{in},t) \\
& \cdot \sum_{\substack{(u,n,d,s,t_{in}) \in ind(unit_{flow}):\\ (u,n,d,t_{in}) \in (u,ng_{in},:to\_node,t)}} unit_{flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& \forall (u, ng_{out}, ng_{in}) \in ind(p_{fix\_ratio\_out\_in\_unit_{flow}}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

This constraint can be extended by a right-hand side constant associated with the $units_{on}$ status of the unit $u$.
```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out}) \in ind(unit_{flow}): \\ (u,n,d,s,t_{out}) \, \in \, (u,ng_{out},:from\_node,s,t)}} unit_{flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& ==  p_{fix\_ratio\_out\_in\_unit_{flow}}(u,ng_{out},ng_{in},t) \\ & \cdot \sum_{\substack{(u,n,d,s,t_{in}) \in ind(unit_{flow}):\\ (u,n,d,s,t_{in}) \in (u,ng_{in},:to\_node,s,t)}} unit_{flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& + p_{coeff_{units_{on}}}(u,ng_{out},ng_{in},t) \\
& \sum_{\substack{(u,s,t_{units_{on}}) \in ind(units_{on}):\\ & (u,s,t_{units_{on}} \in (u,s,t)}} units_{on}(u,s,t_{units_{on}}) \cdot \\
& \min(\Delta t_{units_{on}},\Delta t) \\
& \forall (u, ng_{out}, ng_{in}) \in ind(p_{fix\_ratio\_out\_in\_unit_{flow}}), \\
& \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

TO DO: add other ratio cases max,min, outout,inin

#### Define unit/technology capacity
In a multi-commodity setting, there can be different commodities entering/leaving a certain
technology/unit. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The capacity of the unit must be specified
for at least one of the connected nodes, and induces a constraint on the maximum commodity
flows to this location in each time step. When desirable, the capacity can be specified for a number of nodes.
Note that the capacity can be specified both for input and output nodes.
```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in ind(unit_{flow}): \\ (u,n,d,t') \, \in \, (u,ng,d,t)}} unit_{flow}(u,n,d,s,t') \cdot \Delta t' \\
& <= p_{unit\_capacity}(u,ng,d,t) \\
&  \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units_{on}}) \in ind(units_{on}):\\ \\ & (u,\Delta t_{units_{on}} \in (u,t)}} units_{on}(u,s,t_{units_{on}}) \cdot \min(t_{units_{on}},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{unit\_capacity}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

### Dynamic constraints


#### Commitment constraints
For modeling certain technologies/units, it is important to not only have
$unit_{flow}$ variables of
different commodities, but also model the online ("commitment") status of the unit/technology
at every time step. Therefore, an additional variable $units_{on}$ is introduced. This variable
represents the number of online units of that technology (for a normal unit commitment model,
this variable might be a binary, for investment planning purposes, this might also be an integer
or even a continuous variable).
Commitment variables will be introduced by the following constraints (with corresponding
parameters):
- constraint on `units_on`
- constraint on `units_available`
- constraint on the unit state transition
- constraint on the minimum operating point
- constraint on minimum down time
- constraint on minimum up time
- constraint on ramp rates
(TODO: add references to julia constraints and chapters in docs)

##### Constraint on `units_on` and `units_available`
The number of online units need to be restricted to the number of available units:

```math
\begin{aligned}
&  units_{on}(u,s,t) \\
& <= units_{available}(u,s,t) \\
& \forall (u,s,t) \in ind(units_{on})
\end{aligned}
```
The number of available units itself is constrained by the parameter $p_{number\_of\_units}$ and the variable number of invested unit ()$units_{invested\_available}$):

```math
\begin{aligned}
& units_{available}(u,s,t) \\
& == p_{unit_{availability\_factor}}(u,s,t) \\
& \cdot (p_{number\_of\_units}(u,s,t) \\
& + \sum_{(u,s,t) in ind(units_{invested\_available})} units_{invested\_available}(u,s,t) ) \\
& \forall (u,s,t) \in ind(units_{available})
\end{aligned}
```

The investment formulation is described in chapter [Investments](#Investments). (TODO)

The units on status is furtheron constraint by shutting down and starting up actions. This transition is defined as follows:

```math
\begin{aligned}
& units_{on}(u,s,t_{after}) \\
& - units_{started\_up}(u,s,t_{after}) \\
& + units_{shut\_down}(u,s,t_{after}) \\
& == units_{on}(u,s,t_{before}) \\
& \forall (u,s,t_{after}) \in ind(units_{on}), \\
& \forall t_{before} \in t\_before\_t(t_{after}) : t_{before} \in ind(units_{on}),\\
\end{aligned}
```
##### Constraint on minimum operating point
The minimum operating point of a unit can be based on the $unit_{flow}$'s of
input or output nodes/node groups ng:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in ind(unit_{flow}): \\ (u,n,d,t') \, \in \, (u,ng,d,t)}} unit_{flow}(u,n,d,s,t') \cdot \Delta t' \\
& >= p_{minimum\_operating\_point}(u,ng,d,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
&  \cdot \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units_{on}}) \in ind(units_{on}):\\ \\ & (u,\Delta t_{units_{on}} \in (u,t)}} units_{on}(u,s,t_{units_{on}}) \cdot \min(t_{units_{on}},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{minimum\_operating\_point}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

##### Minimum down time (basic version)

```math
\begin{aligned}
& units_{available}(u,s,t) \\
& - units_{on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ t' >=t-p_{min\_down\_time} && t' <= t}}
units_{shut\_down}(u,s,t') \\
& \forall (u,s,t) \in ind(units_{on})\\
\end{aligned}
```

This constraint can be extended to the use reserves. See [Reserve constraints](#reserve_constraints)

##### Minimum up time (basic version)

```math
\begin{aligned}
& units_{on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ t' >=t-p_{min\_up\_time} && t' <= t}}
units_{started\_up}(u,s,t') \\
& \forall (u,s,t) \in ind(units_{on})\\
\end{aligned}
```
This constraint can be extended to the use reserves. See [Reserve constraints](#reserve_constraints)


#### Ramping constraints

%ramp_up/down
%start_up/shutdown ramp

#### Reserve constraints

%minimum up time
%minimum down time (extended)

%constraints max/min non spin ramp up
% constraint res minimum node state
### Bounds on commodity flows

## Network constraints

### Network representation

### Connection capacity bounds

## Investments

### Capacity transfer

### Early retirement of capacity

## User constraints
