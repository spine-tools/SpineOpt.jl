# Constraints

## Balance constraint

### Nodal balance

In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together.
The energy balance is enforced by the following constraint:

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

### Node injection
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
### Node injection w storage capability

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
& \forall (n,s,t) \in ind(node_{stochastic\_time}) : has\_state(n)\\
\end{aligned}
```
### Node state capacity

To limit the storage content, the $node_{state}$ variable needs be constrained by the following equation:

```math
\begin{aligned}
& node_{state}(n, s, t)\\
& <= p_{node_{state\_cap}} \\
& \forall (n,s,t) \in ind(node_{stochastic\_time}) : has\_state(n)\\
\end{aligned}
```
The discharging and charging behavior of storage nodes can be described through unit(s), representing the link between the storage node and the supply node.
Note that the dis-/charging efficiencies and capacities are properties of these units.
See [Define unit/technology capacity](@ref) and [Conversion constraint / limiting flow shares inprocess / relationship in process](@ref)

TODO: investment storages
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

##### Fixed ratio between output and input unit

The constrained given below enforces a fixed ratio between outgoing and incoming $unit_{flows}$. The constrained is only triggered, if the parameter `p_{fix_ratio_out_in_unit_flow(unit__node__node= u, ng_out, ng_in)}` is defined.
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

The investment formulation is described in chapter [Investments](@ref). (TODO)

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

This constraint can be extended to the use reserves. See [Reserve constraints](@ref)

##### Minimum up time (basic version)

```math
\begin{aligned}
& units_{on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ t' >=t-p_{min\_up\_time} && t' <= t}}
units_{started\_up}(u,s,t') \\
& \forall (u,s,t) \in ind(units_{on})\\
\end{aligned}
```
This constraint can be extended to the use reserves. See [Reserve constraints](@ref)


#### Ramping and reserve constraints

To include ramping and reserve constraints, it is a pre requisit that minimum operation points and maximum capacity constraints are enforced as described above.

For dispatchable units, additional ramping constraints can be introduced. First, the upward ramp of a unit is split into online, start-up and non-spinning ramping contributions.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ !is\_reserve(n)}} unit_{flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ is\_reserve(n) \&\& upward\_reserve(n)}} unit_{flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{before}) \in ind(unit_{flow}): \\ (u,n,d,t_{before}) \, \in \, (u,n,d,t_{before})\\ !is\_reserve(n)}} unit_{flow}(u,n,d,s,t_{before}) \\
& <=  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{ramp\_up\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{ramp\_up\_flow}(u,n,d,s,t_{after})  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{start\_up\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{start\_up\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{non-spinn\_up\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{non-spinn\_up\_flow}(u,n,d,s,t_{after}) \\
& \forall (u,n,d,s,t_{after}) \in ind(\\
& unit_{ramp\_\{up\}\_flow},\\
& unit_{start\_up\_flow},\\
& unit_{non-spinn\_\{up\}\_flow}) \\
& \forall t_{before} \in t\_before\_t(t_{after}) : t_{before} \in ind(unit_{flow}) \\
\end{aligned}
```
Similarly, the downward ramp of a unit is split into online, shut-down and non-spinning downward ramping contributions.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t_{before}) \in ind(unit_{flow}): \\ (u,n,d,t_{before}) \, \in \, (u,n,d,t_{before})\\ !is\_reserve(n)}} unit_{flow}(u,n,d,s,t_{before}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after}) \\ !is\_reserve(n)}} unit_{flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after}) \\ is\_reserve(n) \&\& downward\_reserve(n)}} unit_{flow}(u,n,d,s,t_{after}) \\
& <=  \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{ramp\_down\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{ramp\_down\_flow}(u,n,d,s,t_{after}) \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{shut\_down\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{shut\_down\_flow}(u,n,d,s,t_{after}) \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in ind(unit_{non-spinn\_down\_flow}): \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} unit_{non-spinn\_down\_flow}(u,n,d,s,t_{after}) \\
& \forall (u,n,d,s,t_{after}) \in ind(\\
& unit_{ramp\_\{down\}\_flow},\\
& unit_{shut\_down\_flow},\\
& unit_{non-spinn\_\{down\}\_flow}) \\
& \forall t_{before} \in t\_before\_t(t_{after}) : t_{before} \in ind(unit_{flow}) \\
\end{aligned}
```

##### Constraint on spinning upwards ramp_up
The online ramp up ability of a unit can be constraint by the [ramp\_up\_limit](@ref), expressed as a share of the [unit\_capacity](@ref). With this constraint, ramps can be applied to groups of commodities (e.g. electricity + balancing capacity). Moreover, balancing product might have specific ramping requirements, which can herewith also be enforced.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{ramp\_up\_flow}): \\ (u,n,d) \, \in \, (u,ng,d)}} unit_{ramp\_up\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
 (units_{on}(u,s,t')
 - units_{started\_up}(u,s,t')) \\
& \cdot p_{ramp\_up\_limit}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_ramp\_up)\\
\end{aligned}
```
##### Constraint on upward start up ramp_up

This constraint enforces a limit on the unit ramp during startup process. Usually, we consider only non-balancing commodities. However, it is possible to include them, by adding them to the ramp defining node `ng`.
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{start\_up\_flow}): \\ (u,n,d) \, \in \, (u,ng,d)}} unit_{start\_up\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
& \cdot p_{max\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_start\_up\_ramp)\\
\end{aligned}
```
##### Constraint on upward non-spinning start up ramps

For non-spinning reserves, offline units can be scheduled for reserve provision if they have recovered their minimum down time. If nonspinning reserves are used the minimum down-time constraint becomes:

```math
\begin{aligned}
& units_{available}(u,s,t) \\
& - units_{on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ t' >t-p_{min\_down\_time} && t' <= t}}
units_{shut\_down}(u,s,t') \\
& \sum_{\substack{(u,n,s,t) \in ind(nonspin\_units_{starting\_up}): \\ t \in t\_overlaps\_t(t) \\ (u,s) \in (u,s)}}
  nonspin\_units_{starting\_up}(u,n,s,t)
& \forall (u,s,t) \in ind(units_{on})\\
\end{aligned}
```
TODO: add correct forall, how to simplify?

The ramp a non-spinning unit can provide is constraint through the [max\_res\_startup\_ramp](@ref).

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{non-spinn\_\{up\}\_flow}): \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} unit_{non-spinn\_\{up\}\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in ind(nonspin\_units_{starting\_up}): \\ (u,n,s,t)  \in (u,n,s,t)}} nonspin\_units_{starting\_up}(u,n,s,t)  \\
& \cdot p_{max\_res\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_max\_nonspin\_ramp)\\
\end{aligned}
```
##### Constraint on spinning downward ramps

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{ramp\_down\_flow}): \\ (u,n,d) \, \in \, (u,ng,d)}} unit_{ramp\_down\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
 (units_{on}(u,s,t')
 - units_{started\_up}(u,s,t')) \\
& \cdot p_{ramp\_down\_limit}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_ramp\_down)\\
\end{aligned}
```

##### Constraint on downward shut-down ramps
This constraint enforces a limit on the unit ramp during shutdown process. Usually, we consider only non-balancing commodities. However, it is possible to include them, by adding them to the ramp defining node `ng`.
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{shut\_down\_flow}): \\ (u,n,d) \, \in \, (u,ng,d)}} unit_{shut\_down\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} units_{shut\_down}(u,s,t') \\
& \cdot p_{max\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_shut\_down\_ramp)\\
\end{aligned}
```
##### Constraint on downward non-spinning shut-down ramps
For non-spinning downward reserves, online units can be scheduled for reserve provision through shut down if they have recovered their minimum up time. If nonspinning reserves are used the minimum up-time constraint becomes:
```math
\begin{aligned}
& units_{on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in ind(units_{on}): \\ t' >t-p_{min\_up\_time} && t' <= t}}
units_{started\_up}(u,s,t') \\
& \sum_{\substack{(u,n,s,t) \in ind(nonspin\_units_{shutting\_down}): \\ t \in t\_overlaps\_t(t) \\ (u,s) \in (u,s)}}
  nonspin\_units_{shutting\_down}(u,n,s,t) \\
& \forall (u,s,t) \in ind(units_{on})\\
\end{aligned}
```
TODO: add correct forall, how to simplify?

The ramp a non-spinning unit can provide is constraint through the [max\_res\_shutdown\_ramp](@ref).

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ind(unit_{non-spinn\_\{down\}\_flow}): \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} unit_{non-spinn\_\{down\}\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in ind(nonspin\_units_{shutting\_down}): \\ (u,n,s,t)  \in (u,n,s,t)}} nonspin\_units_{shutting\_down}(u,n,s,t)  \\
& \cdot p_{max\_res\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conversion\_capacity\_to\_unit_{flow}}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_max\_nonspin\_ramp)\\
\end{aligned}
```
##### Constraint on minimum node state for reserve provision
Storage nodes can also contribute to the provision of reserves. The amount of balancing contributions is limited by the ramps of the sotrage unit (see above) and by the node state:
```math
\begin{aligned}
& node_{state}(n_{stor}, s, t)\\
& >= p_{node_{state\_min}} \\
& + \sum_{\substack{(u,n_{res},d,s,t) \in ind(unit_{flow}): \\ u \in ind(unit_{flow};n=n_{stor}) \\ is\_reserve\_node(n_{res}) }} unit_{flow}(u,n_{res},d,s,t)  \\
& \cdot p_{minimum\_reserve\_activation\_time}(n_{res}) \\
& \forall (n_{stor},s,t) \in ind(node_{stochastic\_time}) : has\_state(n)\\
\end{aligned}
```

[comment]: <> (TODO:
%substract non-spinning downward; make this an energy not power balance (add delat t)
%minimum up time (extended)
%minimum down time (extended)
%constraints max/min non spin ramp up
% constraint res minimum node state
%add specifics on how to define e.g. nodal balance, connection capacities for %balancing capacities
%todo add new downward equations
%add additional constraints on unit capacity)

#### Reserve constraints

### Bounds on commodity flows

## Network constraints

### Network representation

### [Pressure driven gas transfer](@id pressure-driven-gas-transfer-math)
#### Maximum node pressure
#### Minimum node pressure
#### [Outer approximation through fixed pressure points](@id constraint-fixed-node-pressure-point)
#### [Linepack storage flexibility](@id line-pack-storage-constraint)
#### [Gas connection flow capacity](@id constraint-connection-flow-gas-capacity)
### [Nodebased lossless DC power flow](@id nodal-lossless-DC)
#### Maximum node voltage angle
#### Minimum node voltage angle
### Connection capacity bounds

## Investments

### Capacity transfer

### Early retirement of capacity

## User constraints
