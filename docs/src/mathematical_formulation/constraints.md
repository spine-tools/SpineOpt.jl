# Constraints

## Balance constraint

### [Nodal balance](@id constraint_nodal_balance)

In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together.
The energy balance is enforced by the following constraint:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& + \sum_{\substack{(conn,n',d_{in},s,t) \in connection\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{connection\_flow}(conn,n',d_{in},s,t)\\
& - \sum_{\substack{(conn,n',d_{out},s,t) \in connection\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{connection\_flow}(conn,n',d_{out},s,t)\\
% & + v_{node\_slack\_pos}(n,s,t) \\
% & - v_{node\_slack\_neg}(n,s,t) \\
& \{>=,==,<=\} \\
& 0 \\
& \forall (n,s,t) \in node\_stochastic\_time\_indices
\end{aligned}
```
TODO: remove node_slack position -> can be handled with an additional unit?\\
TODO: Explain node group/ "is internal" properly
TODO: re-work time indices for this; how does this work for storage nodes?

### [Node injection](@id constraint_node_injection)
The node injection itself represents all local production and consumption, represented by the sum of all $v_{unit\_flow}$:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& == \\
& + \sum_{\substack{(u,n',d_{in},s,t) \in unit\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{unit\_flow}(u,n',d_{in},s,t)\\
& - \sum_{\substack{(u,n',d_{out},s,t) \in unit\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{unit\_flow}(u,n',d_{out},s,t)\\
& - p_{demand}(n,s,t)\\
& \forall (n,s,t) \in node\_stochastic\_time\_indices
\end{aligned}
```
### [Node injection w storage capability](@id constraint_node_injection2)

If a node is to represent a storage, the constraint translates to:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& == \\
& (v_{node\_state}(n, s, t\_before)\\
& - v_{node\_state}(n, s, t) \cdot p_{state\_coeff}(n, t)) \\
&   \cdot \Delta t_{after} \\
&  - v_{node\_state}(n, s, t) \cdot p_{frac\_state\_loss}(n, t) \\
&  + \sum_{\substack{(n2,s,t) \in node\_state\_indices: \\ \exists diff\_coeff(n2,n)}}
v_{node\_state}(n2,s,t)\\
& - \sum_{\substack{(n2,s,t) \in node\_state\_indices: \\ \exists diff\_coeff(n,n2)}}
v_{node\_state}(n2,s,t)\\
& + \sum_{\substack{(u,n',d_{in},s,t) \in unit\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{unit\_flow}(u,n',d_{in},s,t)\\
& - \sum_{\substack{(u,n',d_{out},s,t) \in unit\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{unit\_flow}(u,n',d_{out},s,t)\\
& - demand(n,s,t)\\
& \forall (n,s,t) \in node\_stochastic\_time\_indices : p_{has\_state}(n)\\
\end{aligned}
```
### [Node state capacity](@id constraint_node_state_capacity)

To limit the storage content, the $v_{node\_state}$ variable needs be constrained by the following equation:

```math
\begin{aligned}
& v_{node\_state}(n, s, t)\\
& <= p_{node\_state\_cap} \\
& \forall (n,s,t) \in node\_stochastic\_time\_indices : p_{has\_state}(n)\\
\end{aligned}
```
The discharging and charging behavior of storage nodes can be described through unit(s), representing the link between the storage node and the supply node.
Note that the dis-/charging efficiencies and capacities are properties of these units.
See [the capacity coonstraint](@ref constraint_unit_flow_capacity) and [Conversion constraint / limiting flow shares inprocess / relationship in process](@ref)

TODO: investment storages

### [Cyclic condition on node state variable](@id constraint_cyclic_node_state)
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

##### [Ratios between output and input unit](@id constraint_ratio_unit_flow)

The constrained given below enforces a fixed ratio between outgoing and incoming $v_{unit\_flow}$. The constrained is only triggered, if the parameter `p_{fix_ratio_out_in_unit_flow(unit__node__node= u, ng_out, ng_in)}` is defined.
```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out}) \in unit\_flow\_indices: \\ (u,n,d,t_{out}) \, \in \, (u,ng_{out},:from\_node,t)}} v_{unit\_flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& == p_{fix\_ratio\_out\_in\_unit\_flow}(u,ng_{out},ng_{in},t) \\
& \cdot \sum_{\substack{(u,n,d,s,t_{in}) \in unit\_flow\_indices:\\ (u,n,d,t_{in}) \in (u,ng_{in},:to\_node,t)}} v_{unit\_flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& \forall (u, ng_{out}, ng_{in}) \in ind(p_{fix\_ratio\_out\_in\_unit\_flow}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

This constraint can be extended by a right-hand side constant associated with the $v_{units\_on}$ status of the unit $u$.
```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out}) \in unit\_flow\_indices: \\ (u,n,d,s,t_{out}) \, \in \, (u,ng_{out},:from\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& ==  p_{fix\_ratio\_out\_in\_unit\_flow}(u,ng_{out},ng_{in},t) \\ & \cdot \sum_{\substack{(u,n,d,s,t_{in}) \in unit\_flow\_indices:\\ (u,n,d,s,t_{in}) \in (u,ng_{in},:to\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& + p_{coeff__{units\_on}}(u,ng_{out},ng_{in},t) \\
& \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\ & (u,s,t_{units\_on} \in (u,s,t)}} v_{units\_on}(u,s,t_{units\_on}) \cdot \\
& \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u, ng_{out}, ng_{in}) \in ind(p_{fix\_ratio\_out\_in\_unit\_flow}), \\
& \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

TO DO: add other ratio cases max,min, outout,inin

#### [Define unit/technology capacity](@id constraint_unit_flow_capacity)
In a multi-commodity setting, there can be different commodities entering/leaving a certain
technology/unit. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The capacity of the unit must be specified
for at least one of the connected nodes, and induces a constraint on the maximum commodity
flows to this location in each time step. When desirable, the capacity can be specified for a number of nodes.
Note that the capacity can be specified both for input and output nodes.
```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,t') \, \in \, (u,ng,d,t)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& <= p_{unit\_capacity}(u,ng,d,t) \\
&  \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\ \\ & (u,\Delta t_{units\_on} \in (u,t)}} v_{units\_on}(u,s,t_{units\_on}) \cdot \min(t_{units\_on},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{unit\_capacity}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```
### Dynamic constraints

#### Commitment constraints
For modeling certain technologies/units, it is important to not only have
$v_{unit\_flow}$ variables of
different commodities, but also model the online ("commitment") status of the unit/technology
at every time step. Therefore, an additional variable $v_{units\_on}$ is introduced. This variable
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

##### [Bound on online units](@id constraint_units_on)
The number of online units need to be restricted to the number of available units:

```math
\begin{aligned}
&  v_{units\_on}(u,s,t) \\
& <= v_{units\_available}(u,s,t) \\
& \forall (u,s,t) \in units\_on\_indices
\end{aligned}
```

##### [Bound on available units](@id constraint_units_available)
The number of available units itself is constrained by the parameter $p_{number\_of\_units}$ and the variable number of invested unit ()$v_{units\_invested\_available}$):

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& == p_{unit\_availability\_factor}(u,s,t) \\
& \cdot (p_{number\_of\_units}(u,s,t) \\
& + \sum_{(u,s,t) in units\_invested\_available\_indices} v_{units\_invested\_available}(u,s,t) ) \\
& \forall (u,s,t) \in units\_on\_indices
\end{aligned}
```

The investment formulation is described in chapter [Investments](@ref). (TODO)

##### [Unit state transition](@id constraint_unit_state_transition)
The units on status is furtheron constraint by shutting down and starting up actions. This transition is defined as follows:

```math
\begin{aligned}
& v_{units\_on}(u,s,t_{after}) \\
& - v_{units\_started\_up}(u,s,t_{after}) \\
& + v_{units\_shut\_down}(u,s,t_{after}) \\
& == v_{units\_on}(u,s,t_{before}) \\
& \forall (u,s,t_{after}) \in units\_on\_indices, \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in units\_on\_indices,\\
\end{aligned}
```
##### [Constraint on minimum operating point](@id constraint_minimum_operating_point)
The minimum operating point of a unit can be based on the $v_{unit\_flow}$'s of
input or output nodes/node groups ng:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,t') \, \in \, (u,ng,d,t)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& >= p_{minimum\_operating\_point}(u,ng,d,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
&  \cdot \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\ \\ & (u,\Delta t_{units\_on} \in (u,t)}} v_{units\_on}(u,s,t_{units\_on}) \cdot \min(t_{units\_on},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{minimum\_operating\_point}), \forall t \in timeslices, \forall s \in stochasticpath
\end{aligned}
```

##### [Minimum down time (basic version)](@id constraint_min_down_time)

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& - v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >=t-p_{min\_down\_time} && t' <= t}}
v_{units\_shut\_down}(u,s,t') \\
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```

This constraint can be extended to the use reserves. See also. (TODO)

##### Minimum up time (basic version)

```math
\begin{aligned}
& v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >=t-p_{min\_up\_time}, \\ t' <= t}}
v_{units\_started\_up}(u,s,t') \\
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```
This constraint can be extended to the use reserves. See [also](@ref constraint_min_up_time2)


#### Ramping and reserve constraints

To include ramping and reserve constraints, it is a pre requisit that minimum operation points and maximum capacity constraints are enforced as described above.

For dispatchable units, additional ramping constraints can be introduced. First, the upward ramp of a unit is split into online, start-up and non-spinning ramping contributions.

#### [Splitting unit flows into ramps](@id constraint_split_ramps)
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ !is\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ is\_reserve(n) \&\& upward\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{before}) \in unit\_flow\_indices: \\ (u,n,d,t_{before}) \, \in \, (u,n,d,t_{before})\\ !is\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{before}) \\
& <=  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{ramp\_up\_unit\_flow}(u,n,d,s,t_{after})  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in start\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{start\_up\_unit\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in nonspin\_ramp\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{nonspin\_ramp\_up\_unit\_flow}(u,n,d,s,t_{after}) \\
& \forall (u,n,d,s,t_{after}) \in (\\
& ramp\_up\_unit\_flow\_indices,\\
& start\_up\_unit\_flow\_indices,\\
& nonspin\_ramp\_up\_unit\_flow\_indices) \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in unit\_flow\_indices \\
\end{aligned}
```
Similarly, the downward ramp of a unit is split into online, shut-down and non-spinning downward ramping contributions.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t_{before}) \in unit\_flow\_indices: \\ (u,n,d,t_{before}) \, \in \, (u,n,d,t_{before})\\ !is\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{before}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after}) \\ !is\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after}) \\ is\_reserve(n) \&\& downward\_reserve(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& <=  \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{ramp\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in shut\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{shut\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& \sum_{\substack{(u,n,d,s,t_{after}) \in nonspin\_ramp\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{nonspin\_ramp\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& \forall (u,n,d,s,t_{after}) \in (\\
& ramp\_down\_unit\_flow\_indices,\\
& shut\_down\_unit\_flow\_indices,\\
& nonspin\_ramp\_down\_unit\_flow\_indices) \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in unit\_flow\_indices \\
\end{aligned}
```

##### [Constraint on spinning upwards ramp_up](@id constraint_ramp_up)
The online ramp up ability of a unit can be constraint by the [ramp\_up\_limit](@ref), expressed as a share of the [unit\_capacity](@ref). With this constraint, ramps can be applied to groups of commodities (e.g. electricity + balancing capacity). Moreover, balancing product might have specific ramping requirements, which can herewith also be enforced.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{ramp\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
 (v_{units\_on}(u,s,t')
 - v_{units\_started\_up}(u,s,t')) \\
& \cdot p_{ramp\_up\_limit}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_ramp\_up)\\
\end{aligned}
```
##### [Constraint on minimum upward start up ramp_up](@id constraint_min_start_up_ramp)
##### [Constraint on maximum upward start up ramp_up](@id constraint_max_start_up_ramp)

This constraint enforces a limit on the unit ramp during startup process. Usually, we consider only non-balancing commodities. However, it is possible to include them, by adding them to the ramp defining node `ng`.
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in start\_up\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{start\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
& \cdot p_{max\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_start\_up\_ramp)\\
\end{aligned}
```
##### Constraint on upward non-spinning start up ramps

For non-spinning reserves, offline units can be scheduled for reserve provision if they have recovered their minimum down time. If nonspinning reserves are used the minimum down-time constraint becomes:

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& - v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >t-p_{min\_down\_time} && t' <= t}}
v_{units\_shut\_down}(u,s,t') \\
& \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ t \in t\_overlaps\_t(t) \\ (u,s) \in (u,s)}}
  v_{nonspin\_units\_started\_up}(u,n,s,t)
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```
TODO: add correct forall, how to simplify?

##### [Minimum nonspinning ramp up](@id constraint_min_nonspin_ramp_up)
##### [Maximum nonspinning ramp up](@id constraint_max_nonspin_ramp_up)

The ramp a non-spinning unit can provide is constraint through the [max\_res\_startup\_ramp](@ref).

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_up\_unit\_flow\_indices: \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} v_{nonspin\_ramp\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ (u,n,s,t)  \in (u,n,s,t)}} v_{nonspin\_units\_started\_up}(u,n,s,t)  \\
& \cdot p_{max\_res\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_max\_nonspin\_ramp)\\
\end{aligned}
```
##### [Constraint on spinning downward ramps](@id constraint_ramp_down)

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{ramp\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
 (v_{units\_on}(u,s,t')
 - v_{units\_started\_up}(u,s,t')) \\
& \cdot p_{ramp\_down\_limit}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_ramp\_down)\\
\end{aligned}
```
##### [Lower bound on downward shut-down ramps](@id constraint_min_shut_down_ramp)
##### [Upper bound on downward shut-down ramps](@id constraint_max_shut_down_ramp)
This constraint enforces a limit on the unit ramp during shutdown process. Usually, we consider only non-balancing commodities. However, it is possible to include them, by adding them to the ramp defining node `ng`.
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in shut\_down\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{shut\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} v_{units\_shut\_down}(u,s,t') \\
& \cdot p_{max\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_shut\_down\_ramp)\\
\end{aligned}
```
##### [Constraint on minimum up time, including nonpinning reserves](@id constraint_min_up_time2)
For non-spinning downward reserves, online units can be scheduled for reserve provision through shut down if they have recovered their minimum up time. If nonspinning reserves are used the minimum up-time constraint becomes; TODO check this:
```math
\begin{aligned}
& v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >t-p_{min\_up\_time} && t' <= t}}
v_{units\_started\_up}(u,s,t') \\
& \sum_{\substack{(u,n,s,t) \in nonspin\_units\_shut\_down\_indices: \\ t \in t\_overlaps\_t(t) \\ (u,s) \in (u,s)}}
  v_{nonspin\_units\_shut\_down}(u,n,s,t) \\
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```
TODO: add correct forall, how to simplify?

The ramp a non-spinning unit can provide is constraint through the [max\_res\_shutdown\_ramp](@ref).

#### [Lower bound on the nonspinning downward reserve provision](@id constraint_min_nonspin_ramp_down)
#### [Upper bound on the nonspinning downward reserve provision](@id constraint_max_nonspin_ramp_down)

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_down\_unit\_flow\_indices: \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} v_{nonspin\_ramp\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_shut\_down\_indices: \\ (u,n,s,t)  \in (u,n,s,t)}} v_{nonspin\_units\_shut\_down}(u,n,s,t)  \\
& \cdot p_{max\_res\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,t) \\
& \forall (u,ng,d,s,t) \in ind(constraint\_max\_nonspin\_ramp)\\
\end{aligned}
```
##### [Constraint on minimum node state for reserve provision](@id constraint_res_minimum_node_state)
Storage nodes can also contribute to the provision of reserves. The amount of balancing contributions is limited by the ramps of the sotrage unit (see above) and by the node state:
```math
\begin{aligned}
& v_{node\_state}(n_{stor}, s, t)\\
& >= p_{node\_state\_min} \\
& + \sum_{\substack{(u,n_{res},d,s,t) \in unit\_flow\_indices: \\ u \in unit\_flow\_indices;n=n_{stor}) \\ p_{is\_reserve\_node}(n_{res}) }} v_{unit\_flow}(u,n_{res},d,s,t)  \\
& \cdot p_{minimum\_reserve\_activation\_time}(n_{res}) \\
& \forall (n_{stor},s,t) \in node\_stochastic\_time\_indices : p_{has\_state}(n)\\
\end{aligned}
```

#### [ with ramps](@id constraint_unit_flow_capacity_w_ramps)
Currently not supported, mention issue here

[comment]: <> (TODO:
%substract non-spinning downward; make this an energy not power balance (add delat t)
%minimum up time (extended)
%minimum down time (extended)
%constraints max/min non spin ramp up
% constraint res minimum node state
%add specifics on how to define e.g. nodal balance, connection capacities for %balancing capacities
%todo add new downward equations
%add additional constraints on unit capacity)

### Operating segments
#### [Operating segments of units](@id constraint_operating_point_bounds)
#### [Bounding unit flows by summing over operating segments](@id constraint_operating_point_sum)
#### [Heat rate?](@id constraint_unit_pw_heat_rate)

### Bounds on commodity flows

#### [Upper bound on cumulated unit flows](@id constraint_max_cum_in_unit_flow_bound)

## Network constraints

### Static constraints
#### [Capacity constraint on connections](@id constraint_connection_flow_capacity)
#### [Fixed ratio between outgoing and incoming flows of a connection](@id constraint_ratio_out_in_connection_flow)
### Network representation

### [Pressure driven gas transfer](@id pressure-driven-gas-transfer-math)
#### [Maximum node pressure](@id constraint_max_node_pressure)
#### [Minimum node pressure](@id constraint_min_node_pressure)
#### [Constraint o the pressure ratio between to nodes](@id constraint_compression_ratio)
#### [Outer approximation through fixed pressure points](@id constraint_fixed_node_pressure_point)
#### [Linepack storage flexibility](@id constraint_storage_line_pack)
#### [Gas connection flow capacity](@id constraint_connection_flow_gas_capacity)
#### [Enforcing unidirectional flow](@id constraint_connection_unitary_gas_flow.jl)
### [Nodebased lossless DC power flow](@id nodal-lossless-DC)
#### [Maximum node voltage angle](@id constraint_max_node_voltage_angle)
#### [Minimum node voltage angle](@id constraint_min_node_voltage_angle)
#### [Voltage angle to connection flows](@id constraint_node_voltage_angle)

### [PTDF based DC lossless powerflow ?](@id PTDF-lossless-DC)
#### [connection flow LODF?](@id constraint_connection_flow_lodf)
## Investments
### Investments in units
#### [Economic lifetime of a unit](@id constraint_unit_lifetime)
#### Technical lifetime of a unit
#### [Investment transfer](@id constraint_units_invested_transition)
### Investments in connections
### [Available connection?](@id constraint_connections_invested_available)
### [Transfer of previous investments](@id constraint_connections_invested_transition)
#### [Intact connection flows?](@id constraint_connection_flow_intact_flow)
#### [Intact connection flows capacity?](@id constraint_connection_intact_flow_capacity)
#### [Intact flow ptdf](@id constraint_connection_intact_flow_ptdf)
#### [Fixed ratio between outgoing and incoming intact ? flows of a connection](@id constraint_ratio_out_in_connection_intact_flow)
Note: is this actually an investment or a network constraint?
#### [Lower bound on candidate connection flow](@id constraint_candidate_connection_flow_lb)
#### [Upper bound on candidate connection flow](@id constraint_candidate_connection_flow_ub)
#### [Economic lifetime of a connection](@id constraint_connection_lifetime)
#### Technical lifetime of a connection
### Investments in storages
Note: can we actually invest in nodes that are not storages? (e.g. new location)
#### [Available invested storages](@id constraint_storages_invested_available)
#### [Storage capacity transfer? ](@id constraint_storages_invested_transition)
#### [Economic lifetime of a storage](@id constraint_storage_lifetime)
#### Technical lifetime of a storage
### Capacity transfer

### Early retirement of capacity

## Benders decomposition
Can we add some detail on the mathematics here
### [Benders cuts](@id constraint_mp_any_invested_cuts)
## User constraints
### [Unit constraint](@id constraint_unit_constraint)
