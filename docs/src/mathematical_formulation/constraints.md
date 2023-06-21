# Constraints

## Balance constraint

### [Nodal balance](@id constraint_nodal_balance)
In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together. An energy balance is created for each [node](@ref) for all `node_stochastic_time_indices`, unless the [balance\_type](@ref) parameter of the node takes the value [balance\_type\_none](@ref balance_type_list) or if the node in question is a member of a node group, for which the [balance\_type](@ref) is [balance\_type\_group](@ref balance_type_list). The parameter [nodal\_balance\_sense](@ref) defaults to equality, but can be changed to allow overproduction ([nodal\_balance\_sense](@ref) [`>=`](@ref constraint_sense_list)) or underproduction ([nodal\_balance\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The energy balance is enforced by the following constraint:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& + \sum_{\substack{(conn,n',d_{in},s,t) \in connection\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{connection\_flow}(conn,n',d_{in},s,t)\\
& - \sum_{\substack{(conn,n',d_{out},s,t) \in connection\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{connection\_flow}(conn,n',d_{out},s,t)\\
 & + v_{node\_slack\_pos}(n,s,t) \\
 & - v_{node\_slack\_neg}(n,s,t) \\
& \{>=,==,<=\} \\
& 0 \\
& \forall (n,s,t) \in node\_stochastic\_time\_indices: \\
& p_{balance\_type}(n) != balance\_type\_none \\
& \nexists ng \in groups(n) : balance\_type\_group \\
\end{aligned}
```
The constraint consists of the [node injections](@ref constraint_node_injection), the net [connection\_flow](@ref)s and [node slack variables](@ref Variables).

### [Node injection](@id constraint_node_injection)
The node injection itself represents all local production and consumption, represented by the sum of all connected unit flows and the nodal demand. The node injection is created for each node in the network (unless the node is only used for parameter aggregation purposes, see [Introduction to groups of objects](@ref)).

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

### [Node injection with storage capability](@id constraint_node_injection2)

If a node corresponds to a storage node, the parameter [has\_state](@ref) should be set to [true](@ref boolean_value_list) for this node. In this case the nodal injection will translate to the following constraint:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& == \\
& (v_{node\_state}(n, s, t\_before)\\
& - v_{node\_state}(n, s, t) \cdot p_{state\_coeff}(n,s,t)) \\
&   / \Delta t_{after} \\
&  - v_{node\_state}(n, s, t) \cdot p_{frac\_state\_loss}(n,s,t) \\
&  + \sum_{\substack{(n2,s,t) \in node\_state\_indices: \\ \exists diff\_coeff(n2,n)}}
v_{node\_state}(n2,s,t)\\
& - \sum_{\substack{(n2,s,t) \in node\_state\_indices: \\ \exists diff\_coeff(n,n2)}}
v_{node\_state}(n2,s,t)\\
& + \sum_{\substack{(u,n',d_{in},s,t) \in unit\_flow\_indices: \\ d_{out} == :to\_node}}
 v_{unit\_flow}(u,n',d_{in},s,t)\\
& - \sum_{\substack{(u,n',d_{out},s,t) \in unit\_flow\_indices: \\ d_{out} == :from\_node}}
 v_{unit\_flow}(u,n',d_{out},s,t)\\
& - demand(n,s,t)\\
& \forall (n,t) \in node\_time\_indices : p_{has\_state}(n)\\
& \forall s \in stochastic\_scenario\_path \\
& t_{before} \in t\_before\_t(t\_after=t)\\
\end{aligned}
```

Note that for simplicity, the stochastic path is assumed to be known. In the constraint `constraint_node_injection.jl` the active stochastic paths of all involved variables is retrieved beforehand.

### [Node state capacity](@id constraint_node_state_capacity)

To limit the storage content, the $v_{node\_state}$ variable needs be constrained by the following equation:

```math
\begin{aligned}
& v_{node\_state}(n, s, t)\\
& <= p_{node\_state\_cap}(n, s, t)\\
& \forall (n,s,t) \in node\_stochastic\_time\_indices : \\
& p_{has\_state}(n)\\
\end{aligned}
```
The discharging and charging behavior of storage nodes can be described through unit(s), representing the link between the storage node and the supply node.
Note that the dis-/charging efficiencies and capacities are properties of these units.
See [the capacity constraint](@ref constraint_unit_flow_capacity) and [the unit flow ratio constraints](@ref constraint_ratio_unit_flow)

### [Cyclic condition on node state variable](@id constraint_cyclic_node_state)
To ensure that the node state at the end of the optimization is at least the same value as the initial value at the beginning of the optimization (or higher), the cyclic node state constraint can be used by setting the [cyclic\_condition](@ref) of a [node\_\_temporal\_block](@ref) to `true`. This triggers the following cyclic constraint:

```math
\begin{aligned}
& v_{node\_state}(n, s, t)\\
& >=  v_{node\_state}(n, s, t)\\
& \forall (n,tb) \in p_{cyclic\_condition}(n,tb) : \\
& \{p_{cyclic\_condition}(n,tb) == true,\\
& p_{has\_state}(n) \}\\
& \forall (n',t_{initial}) \in node\_time\_indices : \\
& \{n' == n, \\
& t_{initial} == t\_before\_t(t\_after=first(t \in tb)),\\
& \forall (n',t_{last}) \in node\_time\_indices : \\
& n' == n, \\
& t_{last} == last(t \in tb))\\
& \forall s \in stochastic\_path\\
\end{aligned}
```

## Unit operation

In the following, the operational constraints on the variables associated with units will be elaborated on. The static constraints, in contrast to the dynamic constraints, are addressing constraints without sequential time-coupling. It should however be noted that static constraints can still perform temporal aggregation.

### [Static constraints](@id static-constraints-unit)

The fundamental static constraints for units within SpineOpt relate to the relationships between commodity flows from and to units and to limits on the unit flow capacity.

#### [Conversion constraint / limiting flow shares inprocess / relationship in process](@id constraint_ratio_unit_flow)

A [unit](@ref) can have different commodity flows associated with it. The most simple relationship between these flows is a linear relationship between input and/or output nodes/node groups. SpineOpt holds constraints for each combination of flows and also for the type of relationship, i.e. whether it is a maximum, minimum or fixed ratio between commodity flows. Note that node groups can be used in order to aggregate flows, i.e. to give a ratio between a combination of units flows.

##### [Ratios between output and input flows of a unit](@id ratio_out_in)
By defining the parameters [fix\_ratio\_out\_in\_unit\_flow](@ref),
[max\_ratio\_out\_in\_unit\_flow](@ref) or [min\_ratio\_out\_in\_unit\_flow](@ref), a ratio can be set between **out**going and **in**coming flows from and to a unit.
Whenever there is only a single input node and a single output node, this relationship relates to the notion of an efficiency.
Also, the ratio equation can for instance be used to relate emissions to input primary fuel flows.
In the most general form of the equation, two node groups are defined (an input node group $ng_{in}$ and an output node group $ng_{out}$),
and a linear relationship is expressed between both node groups. Note that whenever the relationship is specified between groups of multiple nodes,
there remains a degree of freedom regarding the composition of the input node flows within group $ng_{in}$  and the output node flows within group $ng_{out}$.

The constraint given below enforces a fixed, maximum or minimum ratio between outgoing and incoming [unit\_flow](@ref). Note that the potential node groups, that the parameters  [fix\_ratio\_out\_in\_unit\_flow](@ref),
[max\_ratio\_out\_in\_unit\_flow](@ref) and [min\_ratio\_out\_in\_unit\_flow](@ref) defined on, are getting internally expanded to the members of the node group within the unit\_flow\_indices.

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out}) \in unit\_flow\_indices: \\ (u,n,d,s,t_{out}) \, \in \, (u,ng_{out},:to\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& \{ \\
& ==  p_{fix\_ratio\_out\_in\_unit\_flow}(u,ng_{out},ng_{in},s,t), \\
& <= p_{max\_ratio\_out\_in\_unit\_flow}(u,ng_{out},ng_{in},s,t), \\
& >= p_{min\_ratio\_out\_in\_unit\_flow}(u,ng_{out},ng_{in},s,t)\\
& \} \\
& \cdot \sum_{\substack{(u,n,d,s,t_{in}) \in unit\_flow\_indices:\\ (u,n,d,s,t_{in}) \in (u,ng_{in},:from\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& + p_{\{fix,max,min\}\_units\_on\_coefficient\_out\_in}(u,ng_{out},ng_{in},s,t) \\
& \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
 (u,s,t_{units\_on}) \in (u,s,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
& \cdot \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u, ng_{out}, ng_{in}) \in ind(p_{\{fix,max,min\}\_ratio\_out\_in\_unit\_flow}), \\
& \forall t \in time\_slices, \forall s \in stochastic\_path
\end{aligned}
```
Note that a right-hand side constant coefficient associated with the variable [units\_on](@ref) can optionally be included, triggered by the existence of the [fix\_units\_on\_coefficient\_out\_in](@ref), [max\_units\_on\_coefficient\_out\_in](@ref), [min\_units\_on\_coefficient\_out\_in](@ref), respectively.

##### [Ratios between input and output flows of a unit](@id ratio_in_out)
Similarly to the ratio between outgoing and incoming unit flows, a ratio can also be defined in reverse between **in**coming and **out**going flows.

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{in}) \in unit\_flow\_indices: \\ (u,n,d,s,t_{in}) \, \in \, (u,ng_{in},:from\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& \{ \\
& ==  p_{fix\_ratio\_in\_out\_unit\_flow}(u,ng_{in},ng_{out},s,t), \\
& <= p_{max\_ratio\_in\_out\_unit\_flow}(u,ng_{in},ng_{out},s,t), \\
& >= p_{min\_ratio\_in\_out\_unit\_flow}(u,ng_{in},ng_{out},s,t)\\
& \} \\
& \cdot \sum_{\substack{(u,n,d,s,t_{out}) \in unit\_flow\_indices:\\ (u,n,d,s,t_{in}) \in (u,ng_{in},:to\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& + p_{\{fix,max,min\}\_units\_on\_coefficient\_in\_out}(u,ng_{in},ng_{out},s,t) \\
& \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
 (u,s,t_{units\_on}) \in (u,s,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
&  \cdot \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u, ng_{in}, ng_{out}) \in ind(p_{\{fix,max,min\}\_ratio\_in\_out\_unit\_flow}), \\
& \forall t \in time\_slices, \forall s \in stochastic\_path
\end{aligned}
```
Note that a right-hand side constant coefficient associated with the variable [units\_on](@ref) can optionally be included, triggered by the existence of the [fix\_units\_on\_coefficient\_in\_out](@ref), [max\_units\_on\_coefficient\_in\_out](@ref), [min\_units\_on\_coefficient\_in\_out](@ref), respectively.

##### [Ratios between input and input flows of a unit](@id ratio_in_in)

Similarly to the [ratio between outgoing and incoming units flows](@ref ratio_out_in), one can also define a fixed, maximum or minimum ratio between **in**coming flows of a units.

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{in1}) \in unit\_flow\_indices: \\ (u,n,d,s,t_{in1}) \, \in \, (u,ng_{in1},:from\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{in1}) \cdot \Delta t_{in1} \\
& \{ \\
& ==  p_{fix\_ratio\_in\_in\_unit\_flow}(u,ng_{in1},ng_{in2},s,t), \\
& <= p_{max\_ratio\_in\_in\_unit\_flow}(u,ng_{in1},ng_{in2},s,t), \\
& >= p_{min\_ratio\_in\_in\_unit\_flow}(u,ng_{in1},ng_{in2},s,t)\\
& \} \\
& \cdot \sum_{\substack{(u,n,d,s,t_{in2}) \in unit\_flow\_indices:\\ (u,n,d,s,t_{in2}) \in (u,ng_{in2},:from\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{in2}) \cdot \Delta t_{in2} \\
& + p_{\{fix,max,min\}\_units\_on\_coefficient\_in\_in}(u,ng_{in1},ng_{in2},s,t) \\
& \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
 (u,s,t_{units\_on}) \in (u,s,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
&  \cdot \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u, ng_{in1}, ng_{in2}) \in ind(p_{\{fix,max,min\}\_ratio\_in\_in\_unit\_flow}), \\
& \forall t \in time\_slices, \forall s \in stochastic\_path
\end{aligned}
```
Note that a right-hand side constant coefficient associated with the variable [units\_on](@ref) can optionally be included, triggered by the existence of the [fix\_units\_on\_coefficient\_in\_in](@ref), [max\_units\_on\_coefficient\_in\_in](@ref), [min\_units\_on\_coefficient\_in\_in](@ref), respectively.

##### [Ratios between output and output flows of a unit](@id ratio_out_out)

Similarly to the [ratio between outgoing and incoming units flows](@ref ratio_out_in), one can also define a fixed, maximum or minimum ratio between **out**going flows of a units.

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t_{out1}) \in unit\_flow\_indices: \\ (u,n,d,s,t_{out1}) \, \in \, (u,ng_{out1},:to\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{out1}) \cdot \Delta t_{out1} \\
& \{ \\
& ==  p_{fix\_ratio\_out\_out\_unit\_flow}(u,ng_{out1},ng_{out2},s,t), \\
& <= p_{max\_ratio\_out\_out\_unit\_flow}(u,ng_{out1},ng_{out2},s,t), \\
& >= p_{min\_ratio\_out\_out\_unit\_flow}(u,ng_{out1},ng_{out2},s,t)\\
& \} \\
& \cdot \sum_{\substack{(u,n,d,s,t_{out2}) \in unit\_flow\_indices:\\ (u,n,d,s,t_{out2}) \in (u,ng_{out2},:to\_node,s,t)}} v_{unit\_flow}(u,n,d,s,t_{out2}) \cdot \Delta t_{out2} \\
& + p_{\{fix,max,min\}\_units\_on\_coefficient\_out\_out}(u,ng_{out1},ng_{out2},s,t) \\
& \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
 (u,s,t_{units\_on}) \in (u,s,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
&  \cdot \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u, ng_{out1}, ng_{out2}) \in ind(p_{\{fix,max,min\}\_ratio\_out\_out\_unit\_flow}), \\
& \forall t \in time\_slices, \forall s \in stochastic\_path
\end{aligned}
```
Note that a right-hand side constant coefficient associated with the variable [units\_on](@ref) can optionally be included, triggered by the existence of the [fix\_units\_on\_coefficient\_out\_out](@ref), [max\_units\_on\_coefficient\_out\_out](@ref), [min\_units\_on\_coefficient\_out\_out](@ref), respectively.

#### [Bounds on the unit capacity](@id constraint_unit_flow_capacity)
In a multi-commodity setting, there can be different commodities entering/leaving a certain
technology/unit. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The [unit\_capacity](@ref) be specified
for at least one [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship, in order to trigger a constraint on the maximum commodity
flows to this location in each time step. When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products).

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,s,t') \, \in \, (u,ng,d,s,t)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& <= p_{unit\_capacity}(u,ng,d,s,t) \\
&  \cdot p_{unit\_availability\_factor}(u,s,t) \\
&  \cdot p_{unit\_conv\_cap\_to\_flow}(u,ng,d,s,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
(u,\Delta t_{units\_on}) \in (u,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
& \cdot \min(t_{units\_on},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{unit\_capacity}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

Note that the conversion factor [unit\_conv\_cap\_to\_flow](@ref) has a default value of `1`, but can be adjusted in case the unit of measurement for the capacity is different to the unit flows unit of measurement.

When the unit also provides non-spinning reserves to a reserve node, the corresponding flows are excluded from the capacity constraint and the unit capacity constraint translates to the following inequality:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,s,t') \, \in \, (u,ng,d,s,t)} \\ n !\in is\_non\_spinning} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& <= p_{unit\_capacity}(u,ng,d,s,t) \\
&  \cdot p_{unit\_availability\_factor}(u,s,t) \\
&  \cdot p_{unit\_conv\_cap\_to\_flow}(u,ng,d,s,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\
(u,\Delta t_{units\_on}) \in (u,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
& \cdot \min(t_{units\_on},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{unit\_capacity}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

### Dynamic constraints

#### Commitment constraints
For modeling certain technologies/units, it is important to not only have
[unit\_flow](@ref) variables of
different commodities, but also model the online ("commitment") status of the unit/technology
at every time step. Therefore, an additional variable [units\_on](@ref) is introduced. This variable
represents the number of online units of that technology (for a normal unit commitment model,
this variable might be a binary, for investment planning purposes, this might also be an integer
or even a continuous variable). To define the type of a commitment variable, see [online\_variable\_type](@ref).
Commitment variables will be introduced by the following constraints (with corresponding
parameters):
- constraint on `units_on`
- constraint on `units_available`
- constraint on the unit state transition
- constraint on the minimum operating point
- constraint on minimum down time
- constraint on minimum up time
- constraint on ramp rates

##### [Bound on available units](@id constraint_units_available)
The aggregated available units itself is constrained by the parameters [unit\_availability\_factor](@ref) and [number\_of\_units](@ref), and the variable number of invested units [units\_invested\_available](@ref):

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& == p_{unit\_availability\_factor}(u,s,t) \\
& \cdot (p_{number\_of\_units}(u,s,t) \\
& + \sum_{(u,s,t) \in units\_invested\_available\_indices} v_{units\_invested\_available}(u,s,t) ) \\
& \forall (u,s,t) \in units\_on\_indices
\end{aligned}
```

##### [Bound on online units](@id constraint_units_on)
The number of online units needs to be restricted to the aggregated available units with respect to the parameter [unit\_availability\_factor](@ref):

```math
\begin{aligned}
& v_{units\_on}(u,s,t) \cdot p_{unit\_availability\_factor}(u,s,t) \\
& <= v_{units\_available}(u,s,t) \\
& \forall (u,s,t) \in units\_on\_indices
\end{aligned}
```

The investment formulation is described in chapter [Investments](@ref).

##### [Unit state transition](@id constraint_unit_state_transition)
The units on status is constrained by shutting down and starting up actions. This transition is defined as follows:

```math
\begin{aligned}
& v_{units\_on}(u,s,t_{after}) \\
& - v_{units\_started\_up}(u,s,t_{after}) \\
& + v_{units\_shut\_down}(u,s,t_{after}) \\
& == v_{units\_on}(u,s,t_{before}) \\
& \forall (u,s,t_{after}) \in units\_on\_indices, \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in units\_on\_indices\\
\end{aligned}
```
##### [Constraint on minimum operating point](@id constraint_minimum_operating_point)
The minimum operating point of a unit can be based on the [unit\_flow](@ref)s of
input or output nodes/node groups ng:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,t') \, \in \, (u,ng,d,t)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& >= p_{minimum\_operating\_point}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
&  \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
&  \cdot \sum_{\substack{(u,s,t_{units\_on}) \in units\_on\_indices:\\ (u,\Delta t_{units\_on} \in (u,t)}} v_{units\_on}(u,s,t_{units\_on}) \\
& \cdot \min(\Delta t_{units\_on},\Delta t) \\
& \forall (u,ng,d) \in ind(p_{minimum\_operating\_point}), \\
& \forall t \in t\_lowest\_resolution(node\_\_temporal\_block(node=members(ng))),\\
&  \forall s \in stochastic\_path
\end{aligned}
```
Note that this constraint is always generated for the lowest resolution of all involved members of the node group `ng`, i.e. the lowest resolution of the involved units flows. This is also why the term ``\min(\Delta t_{units\_on},\Delta t)`` is added for the units on variable, in order to dis-/aggregate the units on resolution to the resolution of the unit flows.

##### [Minimum down time (basic version)](@id constraint_min_down_time)
In order to impose a minimum offline time of a unit, before it can be started up again, the [min\_down\_time](@ref) parameter needs to be defined, which triggers the generation of the following constraint:

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& - v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >=t-p_{min\_down\_time}(u,s,t) \quad t' <= t}}
v_{units\_shut\_down}(u,s,t') \\
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```

Note that for the use reserves the generated minimum down time constraint will include [startups for non-spinning reserves](@ref constraint_min_down_time2).

##### [Minimum up time (basic version)](@id constraint_min_up_time)
Similarly to the [minimum down time constraint](@ref constraint_min_down_time), a minimum time that a unit needs to remain online after a startup can be imposed by defining the [min\_up\_time](@ref) parameter. This will trigger the generation of the following constraint:

```math
\begin{aligned}
& v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >=t-p_{min\_up\_time}(u,s,t), \\ t' <= t}}
v_{units\_started\_up}(u,s,t') \\
& \forall (u,s,t) \in units\_on\_indices\\
\end{aligned}
```
This constraint can be extended to the use of nonspinning reserves. See [also](@ref constraint_min_up_time2).


#### Ramping and reserve constraints

The current documentation on ramping and reserves is presented in a way that is aligned with the SpineOpt modeling logic and data structure, which may sometimes seem counterintuitive for users who are not familiar with this logic and the data structure. For example, in the current documentation the upward and downward reserves appear in the same equation; however, they will not be activated simultaneously given the modeling logic and data structure of SpineOpt. We are currently improving the formulation to make it more computationally efficient and the documentation clearer. We appreciate your patience as we strive to provide clearer and more helpful information.

To include ramping and reserve constraints, it is a pre requisite that [minimum operating points](@ref constraint_minimum_operating_point) and [maximum capacity constraints](@ref constraint_unit_flow_capacity) are enforced as described.

For dispatchable units, additional ramping constraints can be introduced. For setting up ramping characteristics of units see [Ramping and Reserves](@ref).
First, the unit flows are split into their online, start-up, shut-down and non-spinning ramping contributions.

#### [Splitting unit flows into ramps](@id constraint_split_ramps)
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ !p_{is\_reserve}(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ p_{is\_reserve(n)} \\ p_{upward\_reserve}(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})\\ p_{is\_reserve(n)} \\ p_{downward\_reserve}(n)}} v_{unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{before}) \in unit\_flow\_indices: \\ (u,n,d,t_{before}) \, \in \, (u,n,d,t_{before})\\ !p_{is\_reserve}(n)}} v_{unit\_flow}(u,n,d,s,t_{before}) \\
& ==  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{ramp\_up\_unit\_flow}(u,n,d,s,t_{after})  \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in start\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{start\_up\_unit\_flow}(u,n,d,s,t_{after}) \\
& + \sum_{\substack{(u,n,d,s,t_{after}) \in nonspin\_ramp\_up\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{nonspin\_ramp\_up\_unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{ramp\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in shut\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{shut\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& - \sum_{\substack{(u,n,d,s,t_{after}) \in nonspin\_ramp\_down\_unit\_flow\_indices: \\ (u,n,d,t_{after}) \, \in \, (u,n,d,t_{after})}} v_{nonspin\_ramp\_down\_unit\_flow}(u,n,d,s,t_{after}) \\
& \forall (u,n,d,s,t_{after}) \in (\\
& ramp\_up\_unit\_flow\_indices,\\
& start\_up\_unit\_flow\_indices,\\
& nonspin\_ramp\_up\_unit\_flow\_indices, \\
& ramp\_down\_unit\_flow\_indices,\\
& shut\_down\_unit\_flow\_indices,\\
& nonspin\_ramp\_down\_unit\_flow\_indices) \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in unit\_flow\_indices \\
\end{aligned}
```
Note that each *individual* tuple of the `unit_flow_indices` is split into its ramping contributions, if any of the ramping variables exist for this tuple. How to set-up ramps for units is described in [Ramping and Reserves](@ref).

##### [Constraint on spinning upwards ramp_up](@id constraint_ramp_up)
The maximum online ramp up ability of a unit can be constraint by the [ramp\_up\_limit](@ref), expressed as a share of the [unit\_capacity](@ref). With this constraint, online (i.e. spinning) ramps can be applied to groups of commodities (e.g. electricity + balancing capacity). Moreover, balancing product might have specific ramping requirements, which can herewith also be enforced. In case the [max\_startup\_ramp](@ref) is not explicitly defined (its default value is `None` in the template), this formulation would still include the started up units by using the variable `units_started_up`, which is equivalent to what the constraint `constraint_max_start_up_ramp` does with the parameter `max_startup_ramp` being 1.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ramp\_up\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{ramp\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}}
\Big[ \\ 
& \Big((v_{units\_on}(u,s,t') - v_{units\_started\_up}(u,s,t') \Big) \\
& \cdot p_{ramp\_up\_limit}(u,ng,d,s,t) \\
& + \begin{cases}       
       0 & \text{if } p_{max\_startup\_ramp}(u, ng, d) = \textit{None} \\
       v_{units\_started\_up}(u, s, t') & \text{otherwise} \\
    \end{cases} \Big] \\
& \cdot \min(\Delta t',\Delta t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{ramp\_up\_limit})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```
Note that only online units that are not started up during this timestep are considered.
##### [Constraint on minimum upward start up ramp_up](@id constraint_min_start_up_ramp)
To enforce a lower bound on the ramp of a unit during start-up, the [min\_startup\_ramp](@ref) given as a share of the [unit\_capacity](@ref) needs to be defined, which triggers the constraint below. Usually, only non-reserve commodities can have a start-up ramp. However, it is possible to include them, by adding them to the ramp defining node `ng`.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in start\_up\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{start\_up\_unit\_flow}(u,n,d,s,t)  \\
& >= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} v_{units_started\_up}(u,s,t) \\
& \cdot p_{min\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{min\_startup\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```

##### [Constraint on maximum upward start up ramp_up](@id constraint_max_start_up_ramp)

This constraint enforces a upper limit on the unit ramp during startup process, triggered by the existence of the [max\_startup\_ramp](@ref), which should be given as a share of the [unit\_capacity](@ref). Typically, only  ramp flows to non-reserve nodes are considered during the start-up process. However, it is possible to include them, by adding them to the ramp defining node `ng`.
```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in start\_up\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{start\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} v_{units_started\_up}(u,s,t) \\
& \cdot p_{max\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{max\_startup\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```
##### [Constraint on upward non-spinning start ups](@id constraint_min_down_time2)

For non-spinning reserve provision, offline units can be scheduled to provide nonspinning reserves, if they have recovered their minimum down time. If nonspinning reserves are used for a unit, the minimum down-time constraint takes the following form:

```math
\begin{aligned}
& v_{units\_available}(u,s,t) \\
& - v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >t-p_{min\_down\_time}(u,s,t) \\ t' <= t}}
v_{units\_shut\_down}(u,s,t') \\
& + \sum_{\substack{(u',n',s',t') \in nonspin\_units\_started\_up\_indices:\\ (u',s',t') \in (u,s,t)}}
  v_{nonspin\_units\_started\_up}(u',n',s',t') \\
& \forall (u,s,t) \in units\_on\_indices:\\
& (u,n,s,t) \in nonspin\_units\_started\_up\_indices
\end{aligned}
```

##### [Minimum nonspinning ramp up](@id constraint_min_nonspin_ramp_up)

The nonspinning ramp flows of a units [nonspin\_ramp\_up\_unit\_flow](@ref) are dependent on the units holding available for nonspinning reserve provision, i.e. [nonspin\_units\_started\_up](@ref). A lower bound on these nonspinning reserves can be enforced by defining the [min\_res\_startup\_ramp](@ref) parameter (given as a fraction of the [unit\_capacity](@ref)).

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_up\_unit\_flow\_indices: \\ (u,n,d)  \in (u,ng,d)}} v_{nonspin\_ramp\_up\_unit\_flow}(u,n,d,s,t)  \\
& >= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ (u,n)  \in (u,ng}} v_{nonspin\_units\_started\_up}(u,n,s,t)  \\
& \cdot p_{min\_res\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{min\_res\_startup\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```

##### [Maximum nonspinning ramp up](@id constraint_max_nonspin_ramp_up)

The nonspinning ramp flows of a units [nonspin\_ramp\_up\_unit\_flow](@ref) are dependent on the units holding available for nonspinning reserve provision, i.e. [nonspin\_units\_started\_up](@ref). An upper bound on these nonspinning reserves can be enforced by defining the [max\_res\_startup\_ramp](@ref) parameter (given as a fraction of the [unit\_capacity](@ref)).

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_up\_unit\_flow\_indices: \\ (u,n,d)  \in (u,ng,d)}} v_{nonspin\_ramp\_up\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_started\_up\_indices: \\ (u,n)  \in (u,ng}} v_{nonspin\_units\_started\_up}(u,n,s,t)  \\
& \cdot p_{max\_res\_startup\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{max\_res\_startup\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```

##### [Constraint on spinning downward ramps](@id constraint_ramp_down)

Similarly to the online [ramp up capbility](@ref constraint_ramp_up) of a unit,
it is also possible to impose an upper bound on the online ramp down ability of unit by defining a [ramp\_down\_limit](@ref), expressed as a share of the [unit\_capacity](@ref). In case the [max\_shutdown\_ramp](@ref) is not explicitly defined (its default value is `None` in the template), this formulation would still include the shutdown units by using the variable `units_shut_down`, which is equivalent to what the constraint `constraint_max_shut_down_ramp` does with the parameter `max_shutdown_ramp` being 1.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in ramp\_down\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{ramp\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s), \\ t'\in t\_overlap\_t(t)}}
\Big[ \\
& \Big( v_{units\_on}(u,s,t') - v_{units\_started\_up}(u,s,t') \\
& - \sum_{\substack{(u,s,t') \in nonspin\_units\_shut\_down\_indices: \\ 
(u,s,t') \in (u,s,t'), \\ 
\text{if } is\_reserve\_node(n) \text{ and } downward\_reserve(n)}} v_{nonspin\_units\_shut\_down}(u, n, s, t') \Big) \\
& \cdot p_{ramp\_down\_limit}(u,ng,d,s,t) \\
& + \begin{cases}       
       0 & \text{if } p_{max\_shutdown\_ramp}(u, ng, d) = \textit{None} \\
       v_{units\_shut\_down}(u, s, t') & \text{otherwise} \\
    \end{cases} \Big] \\
& \cdot p_{ramp\_down\_limit}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{ramp\_down\_limit})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```

##### [Lower bound on downward shut-down ramps](@id constraint_min_shut_down_ramp)
This constraint enforces a lower bound on the unit ramp during shutdown process. Usually, units will only provide shutdown ramps to non-reserve nodes. However, it is possible to include them, by adding them to the ramp defining node `ng`.
The constraint is triggered by the existence of the [min\_shutdown\_ramp](@ref) parameter.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in shut\_down\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{shut\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} v_{units\_shut\_down}(u,s,t') \\
& \cdot p_{min\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{min\_shutdown\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```
##### [Upper bound on downward shut-down ramps](@id constraint_max_shut_down_ramp)
This constraint enforces an upper bound on the unit ramp during shutdown process. Usually, units will only provide shutdown ramps to non-reserve nodes. However, it is possible to include them, by adding them to the ramp defining node `ng`.
The constraint is triggered by the existence of the [max\_shutdown\_ramp](@ref) parameter.

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in shut\_down\_unit\_flow\_indices: \\ (u,n,d) \, \in \, (u,ng,d)}} v_{shut\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ (u,s) \in (u,s) \\ t'\in t\_overlap\_t(t)}} v_{units\_shut\_down}(u,s,t') \\
& \cdot p_{max\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{max\_shutdown\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```
##### [Constraint on upward non-spinning shut-downs](@id constraint_min_up_time2)
For non-spinning downward reserves, online units can be scheduled for reserve provision through shut down if they have recovered their minimum up time. If nonspinning reserves are used the minimum up-time constraint becomes:

```math
\begin{aligned}
& v_{units\_on}(u,s,t) \\
& >= \sum_{\substack{(u,s,t') \in units\_on\_indices: \\ t' >t-p_{min\_up\_time}(u,s,t) \quad t' <= t}}
v_{units\_started\_up}(u,s,t') \\
& + \sum_{\substack{(u',n',s',t') \in nonspin\_units\_shut\_down\_indices: \\ (u',s',t') \in (u,s,t)}}
  v_{nonspin\_units\_shut\_down}(u',n',s',t') \\
& \forall (u,s,t) \in units\_on\_indices:\\
& u \in nonspin\_units\_started\_up\_indices
\end{aligned}
```

#### [Lower bound on the nonspinning downward reserve provision](@id constraint_min_nonspin_ramp_down)

A lower bound on the nonspinning reserve provision of a unit can be imposed by defining the [min\_res\_shutdown\_ramp](@ref) parameter, which leads to the creation of the following constraint in the model:

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_down\_unit\_flow\_indices: \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} v_{nonspin\_ramp\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_shut\_down\_indices: \\ (u,n,s,t)  \in (u,n,s,t)}} v_{nonspin\_units\_shut\_down}(u,n,s,t)  \\
& \cdot p_{min\_res\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{min\_res\_shutdown\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```

#### [Upper bound on the nonspinning downward reserve provision](@id constraint_max_nonspin_ramp_down)

An upper limit on the nonspinning reserve provision of a unit can be imposed by defining the [max\_res\_shutdown\_ramp](@ref) parameter, which leads to the creation of the following constraint in the model:

```math
\begin{aligned}
& + \sum_{\substack{(u,n,d,s,t) \in nonspin\_ramp\_down\_unit\_flow\_indices: \\ (u,n,d,s,t)  \in (u,n,d,s,t)}} v_{nonspin\_ramp\_down\_unit\_flow}(u,n,d,s,t)  \\
& <= \\
& + \sum_{\substack{(u,n,s,t) \in nonspin\_units\_shut\_down\_indices: \\ (u,n,s,t)  \in (u,n,s,t)}} v_{nonspin\_units\_shut\_down}(u,n,s,t)  \\
& \cdot p_{max\_res\_shutdown\_ramp}(u,ng,d,s,t) \\
& \cdot p_{unit\_capacity}(u,ng,d,s,t) \\
& \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t) \\
& \forall (u,ng,d) \in ind(p_{max\_res\_shutdown\_ramp})\\
& \forall s \in stochastic\_path, \forall t \in time\_slice
\end{aligned}
```
##### [Constraint on minimum node state for reserve provision](@id constraint_res_minimum_node_state)
Storage nodes can also contribute to the provision of reserves. The amount of balancing contributions is limited by the ramps of the storage unit (see above) and by the node state:
```math
\begin{aligned}
& v_{node\_state}(n_{stor}, s, t)\\
& >= p_{node\_state\_min}(n_{stor}, s, t) \\
& + \sum_{\substack{(u,n_{res},d,s,t) \in unit\_flow\_indices: \\ u \in unit\_flow\_indices;n=n_{stor}) \\ p_{is\_reserve\_node}(n_{res}) }} v_{unit\_flow}(u,n_{res},d,s,t)  \\
& \cdot p_{minimum\_reserve\_activation\_time}(n_{res}) \\
& \forall (n_{stor},s,t) \in node\_stochastic\_time\_indices : p_{has\_state}(n)\\
\end{aligned}
```

#### [Bounds on the unit capacity including ramping constraints](@id constraint_unit_flow_capacity_w_ramps)
(Comment 2021-04-29: Currently under development)

### Operating segments
#### [Operating segments of units](@id constraint_operating_point_bounds)
Limit the maximum number of each activated segment `unit_flow_op_active` cannot be higher than the number of online units. This constraint is activated only when parameter [ordered\_unit\_flow\_op](@ref) is set `true`.

```math
\begin{aligned}
& v_{unit\_flow\_op\_active}(u,n,d,op,s,t) <= v_{units\_on}(u,s,t) \\
& \forall (u,n,d,op,s,t) \in unit\_flow\_op\_indices \\
& \text{if } p_{ordered\_unit\_flow\_op}(u)=true \\
\end{aligned}
```

#### [Rank operating segments as per the index of operating points](@id constraint_operating_point_rank)
Rank operating segments by enforcing that the variable `unit_flow_op_active` of operating point `i` can only be active 
if previous operating point `i-1` is also active. The first segment does not need this constraint.

```math
\begin{aligned}
& v_{unit\_flow\_op\_active}(u,n,d,op,s,t) \\
& <= v_{unit\_flow\_op\_active}(u,n,d,op-1,s,t) \\ 
& \forall (u,n,d,op,s,t) \in unit\_flow\_op\_indices \\
& \text{if } op > 1 \\
\end{aligned}
```

#### [Operating segments of units](@id unit_flow_op_bounds)
If the segments of a `unit_flow`, i.e. `unit_flow_op` is not ordered according to the rank of the `unit_flow`'s [operating\_points](@ref) (parameter [ordered\_unit\_flow\_op](@ref) is `false`), the operating segment variable `unit_flow_op` is only bounded by the difference between successive [operating\_points](@ref) adjusted for available capacity. If the order is enforced on the segments (parameter [ordered\_unit\_flow\_op](@ref) is `true`), `unit_flow_op` can only be active if the segment is active (variable [unit\_flow\_op\_active](@ref) is `true`) besides being bounded by the segment capacity.

```math
\begin{aligned}
& v_{unit\_flow\_op}(u, n, d, op, s, t) \\
&  <= p_{unit\_capacity}(u, n, d, s, t) \\
&  \cdot p_{unit\_conv\_cap\_to\_flow}(u, n, d, s, t) \\
&  \cdot p_{unit\_availability\_factor}(u, s, t) \\
&  \cdot \bigg( p_{operating\_points}(u, n, op, s, t) - \begin{cases}       
       0 & \text{if op = 1}\\
       p_{operating\_points}(u, n, op-1, s, t) & \text{otherwise}\\
    \end{cases} \bigg) \\
& \cdot \begin{cases}
            v_{unit\_flow\_op\_active}(u,n,d,op,s,t) & \text{if } p_{ordered\_unit\_flow\_op}(u)=true \\
            v_{units\_on}(u,s,t) & \text{otherwise}\\
        \end{cases}\\
& \forall (u,n,d,op,s,t) \in unit\_flow\_op\_indices \\
\end{aligned}
```

#### [Bounding operating segments to use up its own capacity for activating the next segment](@id unit_flow_op_rank)
Enforce the operating point flow variable `unit_flow_op` at operating point `i` to use its full capacity if the subsequent operating point `i+1` is active if parameter [ordered\_unit\_flow\_op](@ref) is set `true`. The last segment does not need this constraint.

```math
\begin{aligned}
& v_{unit\_flow\_op}(u, n, d, op, s, t) \\
& >= p_{unit\_capacity}(u, n, d, s, t) \\
& \cdot p_{unit\_conv\_cap\_to\_flow}(u, n, d, s, t) \\
& \cdot \bigg(p_{operating\_points}(u, n, op, s, t) - \begin{cases}       
       0 & \text{if } op = 1\\
       p_{operating\_points}(u, n, op-1, s, t) & \text{otherwise}\\
    \end{cases} \bigg) \\
& \cdot v_{unit\_flow\_op\_active}(u, n, d, op+1, s, t) \\
& \forall (u,n,d,op,s,t) \in unit\_flow\_op\_indices \\
& \text{ if } op < op_{last} \text{ and } p_{ordered\_unit\_flow\_op}(u)=true \\
\end{aligned}
```

#### [Bounding unit flows by summing over operating segments](@id unit_flow_op_sum)
`unit_flow` is constrained to be the sum of all operating segment variables, `unit_flow_op`

```math
\begin{aligned}
& v_{unit\_flow}(u, n, d, s, t) \\
&  = \sum_{op}  v_{unit\_flow\_op}(u, n, d, op, s, t) \\
& \forall (u,n,d) \in operating\_point\_indices \\
& \forall (u,n,d,op,s,t) \in unit\_flow\_op\_indices \\
\end{aligned}
```

#### [Unit piecewise incremental heat rate](@id constraint_unit_pw_heat_rate)

```math
\begin{aligned}
              & v_{unit\_flow}(u, n_{in}, d, s, t) \\
              & = \sum_{op} \bigg( v_{unit\_flow\_op}(u, n_{out}, d, op, s, t) \\
              & \qquad \cdot p_{unit\_incremental\_heat\_rate}(u, n_{in}, n_{out}, op, s, t) \bigg) \\              
              & + v_{units\_on}(u, s, t) \cdot p_{unit\_idle\_heat\_rate}(u, n_{in}, n_{out}, s, t) \\
              & + v_{units\_started\_up}(u, s, t) \cdot p_{unit\_start\_flow}(u, n_{in}, n_{out}, s, t) \\
              & \forall (u,n_{in},n_{out},s,t) \in unit\_pw\_heat\_rate\_indices \\
\end{aligned}
```

### Bounds on commodity flows

#### [Bound on cumulated unit flows](@id constraint_total_cumulated_unit_flow)

To impose a limit on the cumulative amount of certain commodity flows, a cumulative bound can be set by defining one of the following parameters:
* [max\_total\_cumulated\_unit\_flow\_from\_node](@ref)
* [max\_total\_cumulated\_unit\_flow\_to\_node](@ref)
* [min\_total\_cumulated\_unit\_flow\_from\_node](@ref)
* [min\_total\_cumulated\_unit\_flow\_to\_node](@ref)

 A maximum cumulated flow restriction can for example be used be used to limit emissions or consumption of a certain commodity. The mathematical implementation will look as follows for flow coming from nodes:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,t') \, \in \, (ug,ng,d)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& \{ \\
& <= p_{max\_total\_cumulated\_unit\_flow\_from\_node}(ug,ng,d) \\
& >= p_{min\_total\_cumulated\_unit\_flow\_from\_node}(ug,ng,d) \\
& \} \\
& \forall (ug,ng,d) \in ind(p_{max\_total\_cumulated\_unit\_flow\_from\_node})
\end{aligned}
```


And the counterpart for flow restrictions to nodes:

```math
\begin{aligned}
& \sum_{\substack{(u,n,d,s,t') \in unit\_flow\_indices: \\ (u,n,d,t') \, \in \, (ug,ng,d)}} v_{unit\_flow}(u,n,d,s,t') \cdot \Delta t' \\
& \{ \\
& <= p_{max\_total\_cumulated\_unit\_flow\_to\_node}(ug,ng,d) \\
& >= p_{min\_total\_cumulated\_unit\_flow\_to\_node}(ug,ng,d) \\
& \} \\
& \forall (ug,ng,d) \in ind(p_{max\_total\_cumulated\_unit\_flow\_from\_node})
\end{aligned}
```


## Network constraints

### [Static constraints](@id static-constraints-connection)

#### [Capacity constraint on connections](@id constraint_connection_flow_capacity)

In a multi-commodity setting, there can be different commodities entering/leaving a certain connection. These can be energy-related commodities (e.g., electricity, natural gas, etc.),
emissions, or other commodities (e.g., water, steel). The [connection\_capacity](@ref) should be specified
for at least one [connection\_\_to\_node](@ref) or [connection\_\_from\_node](@ref) relationship, in order to trigger a constraint on the maximum commodity flows to this location in each time step. When desirable, the capacity can be specified for a group of nodes (e.g. combined capacity for multiple products). Note that the conversion factor [connection\_conv\_cap\_to\_flow](@ref) has a default value of `1`, but can be adjusted in case the unit of measurement for the capacity is different to the connection flows unit of measurement.

```math
\begin{aligned}
& \sum_{\substack{(conn,n,d,s,t') \in connection\_flow\_indices: \\ (conn,n,d,s,t') \, \in \, (conn,ng,d,s,t)}} v_{connection\_flow}(conn,n,d,s,t') \cdot \Delta t' \\
& - \sum_{\substack{(conn,n,d_{reverse},s,t') \in connection\_flow\_indices: \\ (conn,n,s,t') \, \in \, (conn,ng,s,t) \\ d_{reverse} != d}} v_{connection\_flow}(conn,n,d_{reverse},s,t') \cdot \Delta t' \\
& <= p_{connection\_capacity}(conn,ng,d,s,t) \\
& \cdot p_{connection\_availability\_factor}(conn,s,t) \\
&  \cdot p_{connection\_conv\_cap\_to\_flow}(conn,ng,d,s,t) \Delta t\\
& \forall (conn,ng,d) \in ind(p_{connection\_capacity}): \\
& \nexists p_{candidate\_connections}(conn)\\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

If the connection is a [candidate\_connections](@ref), i.e. can be invested in, the connection capacity constraint translates to:

```math
\begin{aligned}
& \sum_{\substack{(conn,n,d,s,t') \in connection\_flow\_indices: \\ (conn,n,d,s,t') \, \in \, (conn,ng,d,s,t)}} v_{connection\_flow}(conn,n,d,s,t') \cdot \Delta t' \\
& - \sum_{\substack{(conn,n,d_{reverse},s,t') \in connection\_flow\_indices: \\ (conn,n,s,t') \, \in \, (conn,ng,s,t) \\ d_{reverse} != d}} v_{connection\_flow}(conn,n,d_{reverse},s,t') \cdot \Delta t' \\
& <= p_{connection\_capacity}(conn,ng,d,s,t) \\
& \cdot p_{connection\_availability\_factor}(conn,s,t) \\
&  \cdot p_{connection\_conv\_cap\_to\_flow}(conn,ng,d,s,t) \Delta t\\
& \cdot \sum_{\substack{(conn,s,t') \in connections\_invested\_available\_indices: \\ (conn,s,t') \, \in \, (conn,s,t\_in\_t(t_{short})}}
v_{connections\_invest\_available(conn, s, t)}
& \forall (conn,ng,d) \in ind(p_{connection\_capacity}): \\
& \exists p_{candidate\_connections}(conn)\\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

#### [Fixed ratio between outgoing and incoming flows of a connection](@id constraint_ratio_out_in_connection_flow)

By defining the parameters [fix\_ratio\_out\_in\_connection\_flow](@ref),
[max\_ratio\_out\_in\_connection\_flow](@ref) or [min\_ratio\_out\_in\_connection\_flow](@ref), a ratio can be set between **out**going and **in**coming flows from and to a connection.

In the most general form of the equation, two node groups are defined (an input node group $ng_{in}$ and an output node group $ng_{out}$),
and a linear relationship is expressed between both node groups. Note that whenever the relationship is specified between groups of multiple nodes,
there remains a degree of freedom regarding the composition of the input node flows within group $ng_{in}$  and the output node flows within group $ng_{out}$.

The constraint given below enforces a fixed, maximum or minimum ratio between outgoing and incoming [connection\_flow](@ref). Note that the potential node groups, that the parameters  [fix\_ratio\_out\_in\_connection\_flow](@ref),
[max\_ratio\_out\_in\_connection\_flow](@ref) and [min\_ratio\_out\_in\_connection\_flow](@ref) are defined on, are getting internally expanded to the members of the node group within the connection\_flow\_indices.

```math
\begin{aligned}
& \sum_{\substack{(conn,n,d,s,t_{out}) \in connection\_flow\_indices: \\ (conn,n,d,s,t_{out}) \, \in \, (conn,ng_{out},:to\_node,s,t)}} v_{connection\_flow}(conn,n,d,s,t_{out}) \cdot \Delta t_{out} \\
& \{ \\
& ==  p_{fix\_ratio\_out\_in\_connection\_flow}(conn,ng_{out},ng_{in},s,t), \\
& <= p_{max\_ratio\_out\_in\_connection\_flow}(conn,ng_{out},ng_{in},s,t), \\
& >= p_{min\_ratio\_out\_in\_connection\_flow}(conn,ng_{out},ng_{in},s,t)\\
& \} \\
& \cdot \sum_{\substack{(conn,n,d,s,t_{in}) \in connection\_flow\_indices:\\ (conn,n,d,s,t_{in}) \in (conn,ng_{in},:from\_node,s,t)}} v_{connection\_flow}(conn,n,d,s,t_{in}) \cdot \Delta t_{in} \\
& \forall (conn, ng_{out}, ng_{in}) \in ind(p_{\{fix,max,min\}\_ratio\_out\_in\_connection\_flow}), \\
& \forall t \in time\_slices, \forall s \in stochastic\_path
\end{aligned}
```

### Specific network representation

In the following, the different specific network representations are introduced. While the [Static constraints](@ref static-constraints-connection) find application in any of the different networks, the following equations are specific to the discussed use cases. Currently, SpineOpt incorporated equations for pressure driven gas networks, nodal lossless DC power flows and PTDF based lossless DC power flow.

#### [Pressure driven gas transfer](@id pressure-driven-gas-transfer-math)
For gas pipelines it can be relevant a pressure driven gas transfer can be modelled, i.e. to account for linepack flexibility. Generally speaking, the main challenges related to pressure driven gas transfers are the non-convexities associated with the Weymouth equation. In SpineOpt, a convexified MILP representation has been implemented, which as been presented in [Schwele - Coordination of Power and Natural Gas Systems: Convexification Approaches for Linepack Modeling](https://doi.org/10.1109/PTC.2019.8810632). The approximation approach is based on the Taylor series expansion around fixed pressure points.

In addition to the already known variables, such as [connection\_flow](@ref) and [node\_state](@ref), the start and end points of a gas pipeline connection are associated with the variable [node\_pressure](@ref). The variable is triggered by the [has\_pressure](@ref) parameter. For more details on how to set up a gas pipeline, see also the advanced concept section [on pressure driven gas transfer](@ref pressure-driven-gas-transfer).

##### [Maximum node pressure](@id constraint_max_node_pressure)

In order to impose an upper limit on the maximum pressure at a node the [maximum node pressure constraint](@ref constraint_max_node_pressure) can be included, by defining the parameter [max\_node\_pressure](@ref) which triggers the following constraint:

```math
\begin{aligned}
& \sum_{\substack{(n,s,t') \in node\_pressure\_indices: \\ (n,s,t') \, \in \, (n,s,t)}} v_{node\_pressure}(n,s,t') \cdot \Delta t' \\
& <= p_{max\_node\_pressure}(ng,s,t) \cdot \Delta t \\
& \forall (ng) \in ind(p_{max\_node\_pressure}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```
As indicated in the equation, the parameter [max\_node\_pressure](@ref) can also be defined on a node group, in order to impose an upper limit on the aggregated [node\_pressure](@ref) within one node group.

##### [Minimum node pressure](@id constraint_min_node_pressure)
In order to impose a lower limit on the pressure at a node the [maximum node pressure constraint](@ref constraint_min_node_pressure) can be included, by defining the parameter [min\_node\_pressure](@ref) which triggers the following constraint:

```math
\begin{aligned}
& \sum_{\substack{(n,s,t') \in node\_pressure\_indices: \\ (n,s,t') \, \in \, (n,s,t)}} v_{node\_pressure}(n,s,t') \cdot \Delta t' \\
& >= p_{min\_node\_pressure}(ng,s,t) \cdot \Delta t \\
& \forall (ng) \in ind(p_{min\_node\_pressure}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```
As indicated in the equation, the parameter [min\_node\_pressure](@ref) can also be defined on a node group, in order to impose a lower limit on the aggregated [node\_pressure](@ref) within one node group.

##### [Constraint on the pressure ratio between two nodes](@id constraint_compression_factor)

If a compression station is located in between two nodes, the connection is considered to be active and a compression ratio between the two nodes can be imposed. The parameter [compression\_factor](@ref) needs to be defined on a [connection\_\_node\_\_node](@ref) relationship, where the first node corresponds the origin node, before the compression, while the second node corresponds to the destination node, after compression. The existence of this parameter will trigger the following constraint:

```math
\begin{aligned}
& \sum_{\substack{(n,s,t') \in node\_pressure\_indices: \\ (n,s,t') \, \in \, (ng2,s,t)}} v_{node\_pressure}(n,s,t') \cdot \Delta t' \\
& <= p_{compression\_factor}(conn,ng1,ng2,s,t) \\
& \sum_{\substack{(n,s,t') \in node\_pressure\_indices: \\ (n,s,t') \, \in \, (ng1,s,t)}} v_{node\_pressure}(n,s,t') \cdot \Delta t' \\
& \forall (conn,ng1,ng2) \in ind(p_{compression\_factor}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

##### [Outer approximation through fixed pressure points](@id constraint_fixed_node_pressure_point)

The Weymouth relates the average flows through a connection to the difference between the adjacent squared node pressures.
```math
\begin{aligned}
  & ((v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 \\
  &   - (v_{connection\_flow}(conn, n_{dest},:from\_node,s,t) + v_{connection\_flow}(conn, n_{orig},:to\_node,s,t))/2)\\
  &   \cdot\\
  & |((v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2\\
  &   - (v_{connection\_flow}(conn, n_{dest},:from\_node,s,t) + v_{connection\_flow}(conn, n_{orig},:to\_node,s,t))/2 |) \\
  &  = K(conn) \cdot (v_{node\_pressure}(n_{orig},s,t)^2 - v_{node\_pressure}(n_{dest},s,t)^2) \\
  \end{aligned}
```
Which can be rewritten as
```math
\begin{aligned}
    & ((v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 \\
    &   - (v_{connection\_flow}(conn, n_{dest},:from\_node,s,t) + v_{connection\_flow}(conn, n_{orig},:to\_node,s,t))/2)\\
    &  =  \sqrt{K(conn) \cdot (v_{node\_pressure}(n_{orig},s,t)^2 - v_{node\_pressure}(n_{dest},s,t)^2)} \\
    & \forall (v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 > 0
  \end{aligned}
```
and
```math
  \begin{aligned}
  & ((v_{connection\_flow}(conn, n_{dest},:from\_node,s,t) + v_{connection\_flow}(conn, n_{orig},:to\_node,s,t))/2\\
  & - (v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2) \\
  &  = \sqrt{K(conn) \cdot (v_{node\_pressure}(n_{dest},s,t)^2 - v_{node\_pressure}(n_{orig},s,t)^2)} \\
    & \forall (v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 < 0
  \end{aligned}
```
where `K` corresponds to the natural gas flow constant.

The cone described by the Weymouth equation can be outer approximated by a number of tangent planes, using a set of fixed pressure points, as illustrated in [Schwele - Integration of Electricity, Natural Gas and Heat Systems With Market-based Coordination](https://orbit.dtu.dk/en/publications/integration-of-electricity-natural-gas-and-heat-systems-with-mark). The bigM method is used to replace the sign function.

The linearized version of the Weymouth equation implemented in SpineOpt is given as follows:

```math
\begin{aligned}
    & ((v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 \\
    &  <= p_{fixed\_pressure\_constant\_1}(conn,n_{orig},n_{dest},j,s,t) \cdot v_{node\_pressure}(n_{orig},s,t) \\
    & - p_{fixed\_pressure\_constant\_0}(conn,n_{orig},n_{dest},j,s,t) \cdot v_{node\_pressure}(n_{dest},s,t) \\
    & + p_{big\_m} \cdot (1 - v_{binary\_gas\_connection\_flow}(conn, n_{dest}, :to\_node, s, t)) \\
    &  \forall (conn, n_{orig}, n_{dest}) \in ind(p_{fixed\_pressure\_constant\_1}) \\
    & \forall j \in 1:n(p_{fixed\_pressure\_constant\_1(connection=conn, node1=n_{orig}, node2=n_dest)}): \\
    & p_{fixed\_pressure\_constant\_1}(conn, n_{orig}, n_{dest}, i=j) != 0 \\
    & \forall t \in time\_slices, \\
    & \forall s \in stochastic\_path
\end{aligned}
```

The parameters [fixed\_pressure\_constant\_1](@ref) and [fixed\_pressure\_constant\_0](@ref) should be defined in the database. For each considered fixed pressure point, they can be calculated as follows:
```math
\begin{aligned}
  & p_{fixed\_pressure\_constant\_1}(conn,n_{orig},n_{dest},j) \\
  & = K(conn) \cdot p_{fixed\_pressure}(n_{orig},j)/ \sqrt{p_{fixed\_pressure}(n_{orig},j)^2 - p_{fixed\_pressure}(n_{dest},j)^2}\\
  & p_{fixed\_pressure\_constant\_0}(conn,n_{orig},n_{dest},j) \\
  & = K(conn) \cdot p_{fixed\_pressure}(n_{dest},j)/ \sqrt{p_{fixed\_pressure}(n_{orig},j)^2 - p_{fixed\_pressure}(n_{dest},j)^2}\\
\end{aligned}
```
where K corrsponds to the natural gas flow constant.

 The [big\_m](@ref) parameter combined with the variable [binary\_gas\_connection\_flow](@ref) together with the equations [on unitary gas flow](@ref constraint_connection_unitary_gas_flow) and on the [maximum gas flow](@ref constraint_connection_flow_gas_capacity) ensure that the bound on the average flow through the fixed pressure points becomes active, if the flow is in a positive direction for the observed set of connection, node1 and node2.

##### [Enforcing unidirectional flow](@id constraint_connection_unitary_gas_flow)

As stated above, the flow through a connection can only be in one direction at at time. Whether a flow is active in a certain direction is indicated by the [binary\_gas\_connection\_flow](@ref) variable, which takes a value of `1` if the direction of flow is positive. To ensure that the [binary\_gas\_connection\_flow](@ref) in the opposite direction then takes the value `0`, the following constraint is enforced:

```math
\begin{aligned}
& v_{binary\_gas\_connection\_flow}(conn, n_{orig}, :to\_node, s, t)) \\
& = (1 - v_{binary\_gas\_connection\_flow}(conn, n_{dest}, :to\_node, s, t)) \\
& \forall (n,d,s,t) \in binary\_gas\_connection\_flow\_indices\\
\end{aligned}
```
##### [Gas connection flow capacity](@id constraint_connection_flow_gas_capacity)

To enforce that the averge flow of a connection is only in one direction, the flow in the opposite direction is forced to be `0` by the following euqation. For the connection flow in the direction of flow the parameter [big\_m](@ref) should be chosen large enough to not become binding.

```math
\begin{aligned}
    & ((v_{connection\_flow}(conn, n_{orig},:from\_node,s,t) + v_{connection\_flow}(conn, n_{dest},:to\_node,s,t))/2 \\
    &  <=  p_{big\_m} \cdot v_{binary\_gas\_connection\_flow}(conn, n_{dest}, :to\_node, s, t) \\
    &  \forall (conn, n_{orig}, n_{dest}) \in ind(p_{fixed\_pressure\_constant\_1}) \\
    & \forall t \in time\_slices, \\
    & \forall s \in stochastic\_path
\end{aligned}
```
##### [Linepack storage flexibility](@id constraint_storage_line_pack)
In order to account for linepack flexibility, i.e. storage capability of a connection, the linepack storage is linked
to the average pressure of the adjacent nodes by the following equation, triggered by the parameter [connection\_linepack\_constant](@ref):

```math
\begin{aligned}
    & v_{node\_state}(n_{stor},s,t) \Delta t \\
    &  = p_{connection\_linepack\_constant}(conn,n_{stor},n_{ngroup}) /2 \sum_{\substack{(n,s,t') \in node\_pressure\_indices: \\ (n,s,t') \, \in \, (ng,s,t)}} v_{node\_pressure}(n,s,t') \cdot \Delta t' \\
    &  \forall (conn, n_{stor}, n_{ngroup}) \in ind(p_{connection\_linepack\_constant}) \\
    & \forall t \in time\_slices, \\
    & \forall s \in stochastic\_path
\end{aligned}
```

Note that the parameter [connection\_linepack\_constant](@ref) should be defined on a [connection\_\_node\_\_node](@ref) relationship, where
the first node corresponds to the linepack storage node, whereas the second node corresponds to the node group of both start and end nodes of the pipeline.

#### [Nodebased lossless DC power flow](@id nodal-lossless-DC)

For the implementation of the nodebased loss DC powerflow model, a new variable [node\_voltage\_angle](@ref) is introduced. See also [has\_voltage\_angle](@ref).
For further explanation on setting up a database for nodal lossless DC power flow, see the advanced concept chapter on [Lossless nodal DC power flows](@ref).

##### [Maximum node voltage angle](@id constraint_max_node_voltage_angle)

In order to impose an upper limit on the maximum voltage angle at a node the [maximum node voltage angle constraint](@ref constraint_max_node_voltage_angle) can be included, by defining the parameter [max\_voltage\_angle](@ref) which triggers the following constraint:

```math
\begin{aligned}
& \sum_{\substack{(n,s,t') \in node\_voltage\_angle\_indices: \\ (n,s,t') \, \in \, (n,s,t)}} v_{node\_voltage\_angle}(n,s,t') \cdot \Delta t' \\
& <= p_{max\_voltage\_angle}(ng,s,t) \\
& \cdot \Delta t \\
& \forall (ng) \in ind(p_{max\_voltage\_angle}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```
As indicated in the equation, the parameter [max\_voltage\_angle](@ref) can also be defined on a node group, in order to impose an upper limit on the aggregated [node\_voltage\_angle](@ref) within one node group.

##### [Minimum node voltage angle](@id constraint_min_node_voltage_angle)

In order to impose a lower limit on the voltage angle at a node the [maximum node voltage angle constraint](@ref constraint_min_node_voltage_angle) can be included, by defining the parameter [min\_voltage\_angle](@ref) which triggers the following constraint:

```math
\begin{aligned}
& \sum_{\substack{(n,s,t') \in node\_voltage\_angle\_indices: \\ (n,s,t') \, \in \, (n,s,t)}} v_{node\_voltage\_angle}(n,s,t') \cdot \Delta t' \\
& >= p_{min\_voltage\_angle}(ng,s,t) \\
& \cdot \Delta t \\
& \forall (ng) \in ind(p_{min\_voltage\_angle}), \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```
As indicated in the equation, the parameter [min\_voltage\_angle](@ref) can also be defined on a node group, in order to impose a lower limit on the aggregated [node\_voltage\_angle](@ref) within one node group.

##### [Voltage angle to connection flows](@id constraint_node_voltage_angle)

To link the flow over a connection to the voltage angles of the adjacent nodes, the following constraint is imposed. Note that this constraint is only generated if
the parameter [connection\_reactance](@ref) is defined for a [connection\_\_node\_\_node](@ref) relationship and if a [fix\_ratio\_out\_in\_connection\_flow](@ref) is defined for the corresponding connection, node, node tuples.

```math
\begin{aligned}
& + \sum_{\substack{(conn,n',d,s,t) \in connection\_flow\_indices: \\ d_{from} == :from\_node \\ n' \in n_{from}}}
 v_{connection\_flow}(conn,n',d,s,t)\\
& - \sum_{\substack{(conn,n',d,s,t) \in connection\_flow\_indices: \\ d_{from} == :from\_node \\ n' \in n_{to}}}
 v_{connection\_flow}(conn,n',s,t)\\
& = \\
& 1/p_{connection\_reactance}(conn) \cdot p_{connection\_reactance\_base}(conn)\\
& \cdot (\sum_{\substack{(n,s,t') \in node\_voltage\_angle\_indices: \\ (n,s,t') \, \in \, (n_{from},s,t)}} v_{node\_voltage\_angle}(n,s,t') \cdot \Delta t' \\
& - \sum_{\substack{(n,s,t') \in node\_voltage\_angle\_indices: \\ (n,s,t') \, \in \, (n_{to},s,t)}} v_{node\_voltage\_angle}(n,s,t') \cdot \Delta t' \\
& (conn, n_{to}, n_{from}) \in indices(p_{fix_ratio_out_in_connection_flow})\\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

### [PTDF based DC lossless powerflow](@id PTDF-lossless-DC)

#### [Connection intact flow PTDF](@id constraint_connection_intact_flow_ptdf)
The power transfer distribution factors are a property of the network reactances. `ptdf(n, c)` represents the fraction of an injection at [node](@ref) n that will flow on [connection](@ref) c. The flow on [connection](@ref) c is then the sum over all nodes of `ptdf(n, c)*net_injection(c)`. [connection\_intact\_flow](@ref) represents the flow on each line of the network will all candidate connections with PTDF-based flow present in the network.

```math
\begin{aligned}
              & + v_{connection\_intact\_flow}(c, n_{to}, d_{to}, s, t) \\
              & - v_{connection\_intact\_flow}(c, n_{to}, d_{from}, s, t) \\
              & == \sum_{n_{inj}} \Big( v_{node\_injection}(n_{inj}, s, t) \cdot p_{ptdf}(c, n_{inj}) \Big) \\              
              & \forall (c,n_{to},s,t) \in connection\_ptdf\_flow\_indices \\
\end{aligned}
```

#### [N-1 post contingency connection flow limits](@id constraint_connection_flow_lodf)
 The N-1 security constraint for the post-contingency flow on monitored connection, `c_mon`, upon the outage of contingency connection, `c_conn`, is formed using line outage distribution factors (lodf). `lodf(c_con, c_mon)` represents the fraction of the pre-contingency flow on connection `c_conn` that will flow on `c_mon` if `c_conn` is disconnected. If [connection](@ref) `c_conn` is disconnected, the post-contingency flow on monitored connection [connection](@ref) `c_mon` is the pre-contingency `connection_flow` on `c_mon` plus the line outage distribution factor (`lodf`) times the pre-contingency `connection_flow` on `c_conn`. This post-contingency flow should be less than the [connection\_emergency\_capacity](@ref) of `c_mon`.
```math
\begin{aligned}
              & + v_{connection\_flow}(c_{mon}, n_{mon\_to}, d_{to}, s, t) \\
              & - v_{connection\_flow}(c_{mon}, n_{mon\_to}, d_{from}, s, t) \\
              & + p_{lodf}(c_{conn}, c_{mon}) \cdot \big( \\              
              & \quad + v_{connection\_flow}(c_{conn}, n_{conn\_to}, d_{to}, s, t) \\
              & \quad - v_{connection\_flow}(c_{conn}, n_{conn\_to}, d_{from}, s, t) \big) \\
              & < min( p_{connection\_emergency\_capacity}(c_{mon}, n_{conn\_to}, d_{to}, s, t), p_{connection\_emergency\_capacity}(c_{mon}, n_{conn\_to}, d_{from},s ,t)) \\
              & \forall (c_{mon}, c_{conn}, s, t) \in constraint\_connection\_flow\_lodf\_indices \\
\end{aligned}
```

## Investments
### Investments in units
#### [Economic lifetime of a unit](@id constraint_unit_lifetime)
(Comment 2023-05-03: Currently under development)
#### Technical lifetime of a unit
(Comment 2021-04-29: Currently under development)

### [Available Investment Units](@id constraint_units_invested_available)
The number of available invested-in units at any point in time is less than the number of investment candidate units.

```math
\begin{aligned}
& v_{units\_invested\_available}(u,s,t) \\
& < p_{candidate\_units}(u,s,t) \\
& \forall u \in candidate\_units\_indices, \\
& \forall (u,s,t) \in units\_invested\_available\_indices\\
\end{aligned}
```

#### [Investment transfer](@id constraint_units_invested_transition)

`units_invested` represents the point-in-time decision to invest in a unit or not while `units_invested_available` represents the invested-in units that are available in a specific timeslice. This constraint enforces the relationship between `units_invested`, `units_invested_available` and `units_mothballed` in adjacent timeslices.

```math
\begin{aligned}
& v_{units\_invested\_available}(u,s,t_{after}) \\
& - v_{units\_invested}(u,s,t_{after}) \\
& + v_{units\_monthballed}(u,s,t_{after}) \\
& == v_{units\_invested\_available}(u,s,t_{before}) \\
& \forall (u,s,t_{after}) \in units\_invested\_available\_indices, \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in units\_invested\_available\_indices\\
\end{aligned}
```
### Investments in connections
### [Available invested-in connections](@id constraint_connections_invested_available)
The number of available invested-in connections at any point in time is less than the number of investment candidate connections.

```math
\begin{aligned}
& v_{connections\_invested\_available}(c,s,t) \\
& < p_{candidate\_connections}(c,s,t) \\
& \forall c \in candidate\_connections\_indices, \\
& \forall (c,s,t) \in connections\_invested\_available\_indices\\
\end{aligned}
```

### [Transfer of previous investments](@id constraint_connections_invested_transition)

`connections_invested` represents the point-in-time decision to invest in a connection or not while `connections_invested_available` represents the invested-in connections that are available in a specific timeslice. This constraint enforces the relationship between `connections_invested`, `connections_invested_available` and `connections_decommissioned` in adjacent timeslices.

```math
\begin{aligned}
& v_{connections\_invested\_available}(c,s,t_{after}) \\
& - v_{connections\_invested}(c,s,t_{after}) \\
& + v_{connections\_decommissioned}(c,s,t_{after}) \\
& == v_{connections\_invested\_available}(c,s,t_{before}) \\
& \forall (c,s,t_{after}) \in connections\_invested\_available\_indices, \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in connections\_invested\_available\_indices\\
\end{aligned}
```
#### [Intact network ptdf-based flows on connections](@id constraint_connection_flow_intact_flow)

Enforces the relationship between [connection\_intact\_flow](@ref) (flow with all investments assumed in force) and [connection\_flow](@ref)
[connection\_intact\_flow](@ref) is the flow on all lines with all investments assumed in place. This constraint ensures that the
[connection\_flow](@ref) is [connection\_intact\_flow](@ref) plus additional flow contributions from investment connections that are not invested in.

```math
\begin{aligned}
              & + v_{connection\_flow}(c, n_{to}, d_{from}, s, t) \\
              & - v_{connection\_flow}(c, n_{to}, d_{to}, s, t) \\
              & - v_{connection\_intact\_flow}(c, n_{to}, d_{from}, s, t) \\
              & + v_{connection\_intact\_flow}(c, n_{to}, d_{to}, s, t) \\
              & ==\\
              & \sum_{c_{candidate}, n_{to_candidate}} p_{lodf}(c_{candidate}, c) \cdot \Big( \\
              & \qquad + v_{connection\_flow}(c_{candidate}, n_{to_candidate}, d_{from}, s, t) \\
              & \qquad - v_{connection\_flow}(c_{candidate}, n_{to_candidate}, d_{to}, s, t) \\
              & \qquad - v_{connection\_intact\_flow}(c_{candidate}, n_{to_candidate}, d_{from}, s, t) \\
              & \qquad + v_{connection\_intact\_flow}(c_{candidate}, n_{to_candidate}, d_{to}, s, t)  \Big) \\              
              & \forall (c,n_{to},s,t) \in connection\_flow\_intact\_flow\_indices \\
\end{aligned}
```

#### [Intact connection flows capacity](@id constraint_connection_intact_flow_capacity)
Similarly to [constraint\_connection\_flow_capacity](@ref), limits [connection\_intact\_flow](@ref) according to [connection\_capacity](@ref)

```math
\begin{aligned}
& \sum_{\substack{(conn,n,d,s,t') \in connection\_intact\_flow\_indices: \\ (conn,n,d,s,t') \, \in \, (conn,ng,d,s,t)}} v_{connection\_intact\_flow}(conn,n,d,s,t') \cdot \Delta t' \\
& - \sum_{\substack{(conn,n,d_{reverse},s,t') \in connection\_intact\_flow\_indices: \\ (conn,n,s,t') \, \in \, (conn,ng,s,t) \\ d_{reverse} != d}} v_{connection\_intact\_flow}(conn,n,d_{reverse},s,t') \cdot \Delta t' \\
& <= p_{connection\_capacity}(conn,ng,d,s,t) \\
& \cdot p_{connection\_availability\_factor}(conn,s,t) \\
&  \cdot p_{connection\_conv\_cap\_to\_flow}(conn,ng,d,s,t) \Delta t\\
& \forall (conn,ng,d) \in ind(p_{connection\_capacity}): \\
& \forall t \in time\_slices, \\
& \forall s \in stochastic\_path
\end{aligned}
```

#### [Fixed ratio between outgoing and incoming intact flows of a connection](@id constraint_ratio_out_in_connection_intact_flow)

For ptdf-based lossless DC power flow, ensures that the output flow to the `to_node` equals the input flow from the `from_node`.

```math
\begin{aligned}              
              & + v_{connection\_intact\_flow}(c, n_{out}, d_{to}, s, t) \\
              & ==\\
              & + v_{connection\_intact\_flow}(c, n_{in}, d_{from}, s, t) \\              
              & \forall (c,n_{in},n_{out},s,t) \in connection\_intact\_flow\_indices \\
\end{aligned}
```

#### [Lower bound on candidate connection flow](@id constraint_candidate_connection_flow_lb)

For candidate connections with PTDF-based poweflow, together with [constraint\_candidate\_connection\_flow\_ub](@ref), this constraint ensures that [connection\_flow](@ref) is zero if the candidate connection is not invested-in and equals [connection\_intact\_flow](@ref) otherwise.

```math
\begin{aligned}              
              & + v_{connection\_flow}(c, n, d, s, t) \\
              & >=\\
              & + v_{connection\_intact\_flow}(c, n, d, s, t) \\              
              & - p_{connection\_capacity}(c, n, d, s, t) \cdot (p_{candidate\_connections}(c, s, t) - v_{connections\_invested\_available}(c, s, t))         \\
              & \forall (c,n,d,s,t) \in constraint\_candidate\_connection\_flow\_lb\_indices \\
\end{aligned}
```

#### [Upper bound on candidate connection flow](@id constraint_candidate_connection_flow_ub)
For candidate connections with PTDF-based poweflow, together with [constraint\_candidate\_connection\_flow\_lb](@ref), this constraint ensures that [connection\_flow](@ref) is zero if the candidate connection is not invested-in and equals [connection\_intact\_flow](@ref) otherwise.

```math
\begin{aligned}              
              & + v_{connection\_flow}(c, n, d, s, t) \\
              & <=\\
              & + v_{connection\_intact\_flow}(c, n, d, s, t) \\              
              \\
              & \forall (c,n,d,s,t) \in constraint\_candidate\_connection\_flow\_ub\_indices \\
\end{aligned}
```

#### [Economic lifetime of a connection](@id constraint_connection_lifetime)
(Comment 2023-05-12: Currently under development)
#### Technical lifetime of a connection
(Comment 2021-04-29: Currently under development)

### Investments in storages
Note: can we actually invest in nodes that are not storages? (e.g. new location)
#### [Available invested storages](@id constraint_storages_invested_available)
The number of available invested-in storages at node n at any point in time is less than the number of investment candidate storages at that node.

```math
\begin{aligned}
& v_{storages\_invested\_available}(n,s,t) \\
& < p_{candidate\_storages}(n,s,t) \\
& \forall (n) \in candidate\_storages\_indices, \\
& \forall (n,s,t) \in storages\_invested\_available\_indices\\
\end{aligned}
```

#### [Storage capacity transfer? ](@id constraint_storages_invested_transition)
`storages_invested` represents the point-in-time decision to invest in storage at a node, n or not while `storages_invested_available` represents the invested-in storages that are available at a node in a specific timeslice. This constraint enforces the relationship between `storages_invested`, `storages_invested_available` and `storages_decommissioned` in adjacent timeslices.

```math
\begin{aligned}
& v_{storages\_invested\_available}(n,s,t_{after}) \\
& - v_{storages\_invested}(n,s,t_{after}) \\
& + v_{storages\_decommissioned}(n,s,t_{after}) \\
& == v_{storages\_invested\_available}(n,s,t_{before}) \\
& \forall (n,s,t_{after}) \in storages\_invested\_available\_indices, \\
& \forall t_{before} \in t\_before\_t(t\_after=t_{after}) : t_{before} \in storages\_invested\_available\_indices\\
\end{aligned}
```
#### [Economic lifetime of a storage](@id constraint_storage_lifetime)
(Comment 2023-05-12: Currently under development)

#### Technical lifetime of a storage
(Comment 2021-04-29: Currently under development)
### Capacity transfer
(Comment 2021-04-29: Currently under development)
### Early retirement of capacity
(Comment 2021-04-29: Currently under development)
## [Benders decomposition](@id benders_decomposition)
This section describes the high-level formulation of the benders-decomposed problem.

Taking the simple example of minimising capacity and operating cost for a fleet of units with a linear cost coefficient $`operational\_cost_u`$ :

```math
\begin{aligned}
minimise:&
\\
&+ \sum_u p_{unit\_investment\_cost}(u) \cdot v_{units\_invested}(u)\\
&+ \sum_{u, n, t} p_{operational\_cost} \cdot v_{unit\_flow}(u, n, t)\\
subject\ to:&
\\
&flow_{u,n,t} \le p_{unit\_capacity}(u, n, t) \cdot (v_{units\_available} + v_{units\_invested\_available}(u, n, t))\\
&\sum_{u,n,t} v_{unit\_flow}(u,t) = p_{demand}(n, t)
\end{aligned}
```

So this is a single problem that can't be decoupled over `t` because the investment variables `units_invested_available` couple the timesteps together. If `units_invested_available` were a constant in the problem, then all `t`'s could be solved individually. This is the basic idea in Benders decomposition. We decompose the problem into a master problem and sub problems with the master problem optimising the coupling investment variables which are treated as constants in the sub problems.

The master problem in the initial benders iteration is simply to minimise total investment costs:

```math
\begin{aligned}
minimise &Z:
\\
&Z \ge \sum_u p_{unit\_investment\_cost}(u) \cdot v_{units\_invested}(u)\\
\end{aligned}

```

The solution to this problem yields values for the investment variables which are fixed as $`\overline{units\_invested_u}`$ in the sub problem and will be zero in the first iteration.

The sub problem for benders iteration `b` then becomes :

```math
\begin{aligned}
minimise:&
\\
obj_b = &+ \sum_{u,n,t} p_{operational\_cost}(u) \cdot v_{unit\_flow}(u,n,t)\\
subject\ to:&
\\
&v_{unit_flow}(u,n,t) \le p_{unit\_capacity}(u) \cdot (v_{units\_available}(u,t) + p_{units\_invested\_available}(u, t)) \qquad \mu_{b,u,t} \\
&\sum_{u,n,t} v_{unit_flow}(u, n, t) = p_{demand}(n, t) \\
\\
\end{aligned}
```
This sub problem can be solved individually for each `t`. This is pretty trivial in this small example but if we consider a single t to be a single rolling horizon instead, decoupling the investment variables means that each rolling horizon can be solved individually rather than having to solve the entire model horizon as a single problem.

$`\mu_{u,t}`$ is the marginal value of the capacity constraint and can be interpreted as the decrease in the objective function at time `t` for an additional MW of flow from unit `u`. This information is used to construct a benders cut which represents the reduction in the sub problem objective function which is possible in this benders iteration by adjusting the variable units_investment. This is effectively the decrease in operating costs possible by adding another unit of type `u` and is expressed as :

$`obj_{b} + \sum_{u,t}p_{unit\_capacity}(u,n,t) \cdot \mu_{b,u,t} \cdot (v_{units\_invested}(u,t) - p_{units\_invested}(u,b,t))`$

In the first benders iteration, the value of the investment variables will have been zero so $`p_{units\_invested}(u,b,t)`$ will have the value of zero and thus the expression represents the total reduction in cost from an addition of a new unit of type `u`. This Benders cut is added to the master problem which then becomes, for each subsequent benders iteration, b:

```math
\begin{aligned}
minimise &Z:
\\
&Z \ge \sum_{u,t} p_{unit\_investment\_cost}(u) \cdot v_{units\_invested}(u,t)\\
subject\ to:&
\\
Z \ge& + \sum_u p_{unit\_investment\_cost}(u) \cdot v_{units\_invested}(u,t)\\
& + \sum_{u,t}p_{unit\_capacity}(u,t) \cdot \mu_{b,u,t} \cdot (v_{units\_invested}(u,t) - p_{units\_invested}(u,b,t)) \qquad \forall b \\
\end{aligned}
```
Note the benders cuts are added as inequalities because they represent an upper bound on the value we are going to get from adjusting the master problem variables in that benders iteration. If we consider the example of renewable generation - because it's marginal cost is zero, on the first benders iteration, it could look like there would be a lot of value in increasing the capacity because of the marginal values from the sub problems. However, when the capacity variables are increased accordingly and curtailment occurs in the sub-problems, the marginal values will be zero when curtailment occurs and so, other resources may become optimal in subsequent iterations.

This is a simple example but it illustrates the general strategy. The algorithm pseudo code looks something like this:

```
  initialise master problem
  initialise sub problem
  solve first master problem
  create master problem variable time series
  solve rolling spine opt model
  save zipped marginal values
  while master problem not converged
      update master problem
      solve master problem
      update master problem variable timeseries for benders iteration b
      rewind sub problem
      update sub problem
      solve rolling spine opt model
      save zipped marginal values
      test for convergence
  end
```

### [Benders cuts](@id constraint_mp_any_invested_cuts)
The benders cuts for the problem including all investments in candidate connections, storages and units is given below.


```math
\begin{aligned}
&v_{objective\_lower\_bound}(b)\\
&>=\\
& + \sum_{u,s,t} p_{units\_invested\_available\_mv}(u,t,b) \cdot \lbrack v_{units\_invested\_available}(u,s,t)-p_{units\_invested\_available\_bi}(u,t,b) \rbrack \\
& + \sum_{c,s,t} p_{connections\_invested\_available\_mv}(c,t,b) \cdot \lbrack v_{connections\_invested\_available}(c,s,t)-p_{connections\_invested\_available\_bi}(c,t,b) \rbrack \\
& + \sum_{n,s,t} p_{storages\_invested\_available\_mv}(n,t,b) \cdot \lbrack v_{storages\_invested\_available}(n,s,t)-p_{storages\_invested\_available\_bi}(n,t,b) \rbrack \\
\end{aligned}
```

where

$`p_{units\_invested\_available\_mv}`$ is the reduced cost of the [units\_invested\_available](@ref) fixed sub-problem variable, representing the reduction in operating costs possible from an investment in a [unit](@ref) of this type,  
$`p_{connections\_invested\_available\_mv}`$ is the reduced cost of the [connections\_invested\_available](@ref) fixed sub-problem variable, representing the reduction in operating costs possible from an investment in a [connection](@ref) of this type,  
$`p_{storages\_invested\_available\_mv}`$ is the reduced cost of the [storages\_invested\_available](@ref) fixed sub-problem variable, representing the reduction in operating costs possible from an investment in a `storage` of this type,  
$`p_{units\_invested\_available\_bi}(u,t,b)`$ is the value of the fixed sub problem variable [units\_invested\_available](@ref)(u,t) in benders iteration `b`,  
$`p_{connections\_invested\_available\_bi}(c,t,b)`$ is the value of the fixed sub problem variable [connections\_invested\_available](@ref)(c,t) in benders iteration `b` and  
$`p_{storages\_invested\_available\_bi}(n,t,b)`$ is the value of the fixed sub problem variable [storages\_invested\_available](@ref)(n,t) in benders iteration `b`


## User constraints
### [User constraint](@id constraint_user_constraint)
The [user\_constraint](@ref) is a generic data-driven [custom constraint](@ref constraint_user_constraint),
which allows for defining constraints involving multiple [unit](@ref)s, [node](@ref)s, or [connection](@ref)s.
The [constraint\_sense](@ref) parameter changes the sense of the [user\_constraint](@ref),
while the [right\_hand\_side](@ref) parameter allows for defining the constant terms of the constraint.

Coefficients for the different [variables](@ref Variables) appearing in the [user\_constraint](@ref) are defined
using relationships, like e.g. [unit\_\_from\_node\_\_user\_constraint](@ref) and
[connection\_\_to\_node\_\_user\_constraint](@ref) for [unit\_flow](@ref) and [connection\_flow](@ref) variables,
or [unit\_\_user\_constraint](@ref) and [node\_\_user\_constraint](@ref) for [units\_on](@ref), [units\_started\_up](@ref),
and [node_state](@ref) variables.

For more information, see the dedicated article on [User Constraints](@ref)

```math
\begin{aligned}
&+\sum_{\substack{u,n \in unit\_\_node\_\_user\_constraint(uc),t,s}} \\
& \begin{cases}       
  \begin{aligned}
       \sum_{\substack{op}} v_{unit\_flow\_op}(u,n,d,op,s,t) \cdot p_{unit\_flow\_coefficient}(u,n,op,uc,s,t) \qquad  &\text{if } \vert operating\_points(u)\vert > 1\\       
       v_{unit\_flow}(u,n,d,s,t) \cdot p_{unit\_flow\_coefficient}(u,n,uc,s,t) \qquad &\text{otherwise}\\       
  \end{aligned}
  \end{cases}\\
&+\sum_{\substack{u \in unit\_\_user\_constraint(uc),t,s}} v_{units\_started\_up}(u,s,t) \cdot p_{units\_started\_up\_coefficient}(u,uc,s,t)\\
&+\sum_{\substack{u \in unit\_\_user\_constraint(uc),t,s}} v_{units\_on}(u,s,t) \cdot p_{units\_on\_coefficient}(u,uc,s,t)\\
&+\sum_{\substack{c,n \in connection\_\_node\_\_user\_constraint(uc),t,s}} v_{connection\_flow}(c,n,d,s,t) \cdot p_{connection\_flow\_coefficient}(c,n,uc,s,t)\\
&+\sum_{\substack{n \in node\_\_user\_constraint(uc),t,s}} v_{node\_state}(n,s,t) \cdot p_{node\_state\_coefficient}(n,uc,s,t)\\
&+\sum_{\substack{n \in node\_\_user\_constraint(uc),t,s}} p_{demand}(n,s,t) \cdot p_{demand\_coefficient}(n,uc,s,t)\\
& \begin{cases}  
  \begin{aligned}     
       == \qquad &\text{if } p_{constraint\_sense}(uc) \text{= "=="}\\
       >= \qquad &\text{if } p_{constraint\_sense}(uc) \text{= ">="}\\
       <= \qquad &\text{otherwise}\\
  \end{aligned}
  \end{cases}\\
&+p_{right\_hand\_side}(uc,t,s)\\
&\forall uc,t,s \in constraint\_user\_constraint\_indices\\
\end{aligned}
```
