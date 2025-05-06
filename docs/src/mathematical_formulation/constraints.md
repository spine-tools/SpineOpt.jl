# Constraints

## Balance constraint

### [Nodal balance](@id constraint_nodal_balance)

@@add_constraint_nodal_balance!

### [Node injection](@id constraint_node_injection)

@@add_constraint_node_injection!

### [Node state capacity](@id constraint_node_state_capacity)

@@add_constraint_node_state_capacity!

### [Minimum node state](@id min_node_state)

@@add_constraint_min_node_state!

### [Cyclic condition on node state variable](@id constraint_cyclic_node_state)

@@add_constraint_cyclic_node_state!

## Unit operation

In the following, the operational constraints on the variables associated with units will be elaborated on. The static constraints, in contrast to the dynamic constraints, are addressing constraints without sequential time-coupling. It should however be noted that static constraints can still perform temporal aggregation.

### [Static constraints](@id static-constraints-unit)

The fundamental static constraints for units within SpineOpt relate to the relationships between commodity flows from and to units and to limits on the unit flow capacity.

#### [Conversion constraint / limiting flow shares inprocess / relationship in process](@id constraint_ratio_unit_flow)

A [unit](@ref) can have different commodity flows associated with it. The most simple relationship between these flows is a linear relationship between input and/or output nodes/node groups. SpineOpt holds constraints for each combination of flows and also for the type of relationship, i.e. whether it is a maximum, minimum or fixed ratio between commodity flows. Note that node groups can be used in order to aggregate flows, i.e. to give a ratio between a combination of units flows.

##### [Ratios between flows of a unit](@id ratio_unit_flow)

@@add_constraint_ratio_unit_flow!

##### [Bounds on the unit capacity](@id constraint_unit_flow_capacity)

@@add_constraint_unit_flow_capacity!

##### [Constraint on minimum operating point](@id constraint_minimum_operating_point)

@@add_constraint_minimum_operating_point!

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
- constraint on minimum down time
- constraint on minimum up time
- constraint on ramp rates
- constraint on reserve provision

##### [Bound on available units](@id constraint_units_available)

@@add_constraint_units_available!

##### [Unit state transition](@id constraint_unit_state_transition)

@@add_constraint_unit_state_transition!

##### [Minimum down time](@id constraint_min_down_time)

@@add_constraint_min_down_time!

##### [Minimum up time](@id constraint_min_up_time)

@@add_constraint_min_up_time!

#### Ramping constraints

To include ramping and reserve constraints, it is a pre requisite that [minimum operating points](@ref constraint_minimum_operating_point) and [capacity constraints](@ref constraint_unit_flow_capacity) are enforced as described.

For dispatchable units, additional ramping constraints can be introduced. For setting up ramping characteristics of units see [Ramping](@ref).

##### [Ramp up limit](@id constraint_ramp_up)

@@add_constraint_ramp_up!

##### [Ramp down limit](@id constraint_ramp_down)

@@add_constraint_ramp_down!

#### Reserve constraints

##### [Constraint on minimum node state for reserve provision](@id constraint_res_minimum_node_state)
(Comment 2023-11-20: Currently under development)

### Operating segments
#### [Operating segments of units](@id constraint_operating_point_bounds)

@@add_constraint_operating_point_bounds!

#### [Rank operating segments as per the index of operating points](@id constraint_operating_point_rank)

@@add_constraint_operating_point_rank!

#### [Operating segments of units](@id unit_flow_op_bounds)

@@add_constraint_unit_flow_op_bounds!

#### [Bounding operating segments to use up its own capacity for activating the next segment](@id unit_flow_op_rank)

@@add_constraint_unit_flow_op_rank!

#### [Bounding unit flows by summing over operating segments](@id unit_flow_op_sum)

@@add_constraint_unit_flow_op_sum!

### Bounds on commodity flows

#### [Bound on cumulated unit flows](@id constraint_total_cumulated_unit_flow)

@@add_constraint_total_cumulated_unit_flow!

## Network constraints

### [Static constraints](@id static-constraints-connection)

#### [Capacity constraint on connections](@id constraint_connection_flow_capacity)

@@add_constraint_connection_flow_capacity!

#### [Fixed ratio between outgoing and incoming flows of a connection](@id constraint_ratio_out_in_connection_flow)

@@add_constraint_ratio_out_in_connection_flow!

### Specific network representation

In the following, the different specific network representations are introduced. While the [Static constraints](@ref static-constraints-connection) find application in any of the different networks, the following equations are specific to the discussed use cases. Currently, SpineOpt incorporated equations for pressure driven gas networks, nodal lossless DC power flows and PTDF based lossless DC power flow.

#### [Pressure driven gas transfer](@id pressure-driven-gas-transfer-math)
For gas pipelines it can be relevant a pressure driven gas transfer can be modelled, i.e. to account for linepack flexibility. Generally speaking, the main challenges related to pressure driven gas transfers are the non-convexities associated with the Weymouth equation. In SpineOpt, a convexified MILP representation has been implemented, which as been presented in [Schwele - Coordination of Power and Natural Gas Systems: Convexification Approaches for Linepack Modeling](https://doi.org/10.1109/PTC.2019.8810632). The approximation approach is based on the Taylor series expansion around fixed pressure points.

In addition to the already known variables, such as [connection\_flow](@ref) and [node\_state](@ref), the start and end points of a gas pipeline connection are associated with the variable [node\_pressure](@ref). The variable is triggered by the [has\_pressure](@ref) parameter. For more details on how to set up a gas pipeline, see also the advanced concept section [on pressure driven gas transfer](@ref pressure-driven-gas-transfer).

##### [Maximum node pressure](@id constraint_max_node_pressure)

@@add_constraint_max_node_pressure!

##### [Minimum node pressure](@id constraint_min_node_pressure)

@@add_constraint_min_node_pressure!

##### [Constraint on the pressure ratio between two nodes](@id constraint_compression_factor)

@@add_constraint_compression_ratio!

##### [Outer approximation through fixed pressure points](@id constraint_fixed_node_pressure_point)

@@add_constraint_fix_node_pressure_point!

##### [Enforcing unidirectional flow](@id constraint_connection_unitary_gas_flow)

@@add_constraint_connection_unitary_gas_flow!

##### [Gas connection flow capacity](@id constraint_connection_flow_gas_capacity)

@@add_constraint_connection_flow_gas_capacity!

##### [Linepack storage flexibility](@id constraint_storage_line_pack)

@@add_constraint_storage_line_pack!

#### [Node-based lossless DC power flow](@id nodal-lossless-DC)

For the implementation of the nodebased loss DC powerflow model, a new variable [node\_voltage\_angle](@ref) is introduced. See also [has\_voltage\_angle](@ref).
For further explanation on setting up a database for nodal lossless DC power flow, see the advanced concept chapter on [Lossless nodal DC power flows](@ref).

##### [Maximum node voltage angle](@id constraint_max_node_voltage_angle)

@@add_constraint_max_node_voltage_angle!

##### [Minimum node voltage angle](@id constraint_min_node_voltage_angle)

@@add_constraint_min_node_voltage_angle!

##### [Voltage angle to connection flows](@id constraint_node_voltage_angle)

@@add_constraint_node_voltage_angle!

### [PTDF based DC lossless powerflow](@id PTDF-lossless-DC)

#### [Connection intact flow PTDF](@id constraint_connection_intact_flow_ptdf)

@@add_constraint_connection_intact_flow_ptdf!

#### [N-1 post contingency connection flow limits](@id constraint_connection_flow_lodf)

@@add_constraint_connection_flow_lodf!

## Investments
### Investments in units

#### [Technical lifetime of a unit](@id constraint_unit_lifetime)

@@add_constraint_unit_lifetime!

### [Available Investment Units](@id constraint_units_invested_available)

@@add_constraint_units_invested_available!

#### [Investment transfer](@id constraint_units_invested_transition)

@@add_constraint_units_invested_transition!

### Investments in connections
### [Available invested-in connections](@id constraint_connections_invested_available)

@@add_constraint_connections_invested_available!

### [Transfer of previous investments](@id constraint_connections_invested_transition)

@@add_constraint_connections_invested_transition!

#### [Intact network ptdf-based flows on connections](@id constraint_connection_flow_intact_flow)

@@add_constraint_connection_flow_intact_flow!

#### [Intact connection flow capacity](@id constraint_connection_intact_flow_capacity)

@@add_constraint_connection_intact_flow_capacity!

#### [Fixed ratio between outgoing and incoming intact flows of a connection](@id constraint_ratio_out_in_connection_intact_flow)

@@add_constraint_ratio_out_in_connection_intact_flow!

#### [Lower bound on candidate connection flow](@id constraint_candidate_connection_flow_lb)

@@add_constraint_candidate_connection_flow_lb!

#### [Upper bound on candidate connection flow](@id constraint_candidate_connection_flow_ub)

@@add_constraint_candidate_connection_flow_ub!

#### [Technical lifetime of a connection](@id constraint_connection_lifetime)

@@add_constraint_connection_lifetime!

### Investments in storages
Note: can we actually invest in nodes that are not storages? (e.g. new location)

#### [Available invested storages](@id constraint_storages_invested_available)

@@add_constraint_storages_invested_available!

#### [Storage capacity transfer ](@id constraint_storages_invested_transition)

@@add_constraint_storages_invested_transition!

#### [Technical lifetime of a storage](@id constraint_storage_lifetime)

@@add_constraint_storage_lifetime!

### Capacity transfer
(Comment 2021-04-29: Currently under development)

### Early retirement of capacity
(Comment 2021-04-29: Currently under development)

## User constraints
### [User constraint](@id constraint_user_constraint)

@@add_constraint_user_constraint!

## [Benders decomposition](@id benders_decomposition)
This section describes the high-level formulation of the benders-decomposed problem.

Taking the simple example of minimising capacity and operating cost for a fleet of units with a linear cost coefficient
``p^{operational\_cost}``:

```math
\begin{aligned}
min&
\\
& \sum_{u,s,t} \left( p^{unit\_investment\_cost}_{(u,s,t)} \cdot v^{units\_invested}_{(u,s,t)}
+ \sum_{n,d} p^{operational\_cost}_{(u,n,d,s,t)} \cdot v^{unit\_flow}_{(u, n, d, s, t)} \right) \\
s.t. &
\\
& v^{unit\_flow}_{(u,n,d,s,t)} \le p^{unit\_capacity}_{(u, n, d, s, t)} \cdot \left(
    v^{units\_available}_{(u,s,t)} + v^{units\_invested\_available}_{(u, s, t)}
\right) \quad \forall u \in unit, n \in node, s, t
\\
& \sum_{u,d} v^{unit\_flow}_{(u,n,d,s,t)} = p^{demand}_{(n, s, t)} \quad \forall n \in node, s,t
\end{aligned}
```

So this is a single problem that can't be decoupled over ``t`` because the investment variables
[units\_invested\_available](@ref) couple the timesteps together.
If [units\_invested\_available](@ref) were a constant in the problem, then all ``t``'s could be solved individually.
This is the basic idea in Benders decomposition.
We decompose the problem into a master problem and sub problems with the master problem
optimising the coupling investment variables which are treated as constants in the sub problems.

The master problem is built by replacing the operational costs (which will be minimised in the sub problem) by
a new decision variable, ``v^{sp\_objective}``:

```math
\begin{aligned}
min & \\
& \sum_{u,s,t} p^{unit\_investment\_cost}_{(u,s,t)} \cdot v^{units\_invested}_{(u,s,t)} + v^{sp\_objective} \\
s.t. & \\
& v^{sp\_objective} \geq 0
\end{aligned}

```

The solution to this problem yields values for the investment variables which are fixed
as ``p^{units\_invested\_available}`` in the sub problem and will be zero in the first iteration.

The sub problem for benders iteration ``b`` then becomes :

```math
\begin{aligned}
min&
\\
& sp\_obj_b = \sum_{u,n,d,s,t} p^{operational\_cost}_{(u,n,d,s,t)} \cdot v^{unit\_flow}_{(u, n, d, s, t)}\\
s.t.&
\\
& v^{unit\_flow}_{(u,n,d,s,t)} \le p^{unit\_capacity}_{(u, n, d, s, t)} \cdot \left(
    v^{units\_available}_{(u,s,t)} + p^{units\_invested\_available}_{(b, u, s, t)}
\right) \\ 
& \qquad \forall u \in unit, n \in node, s,t \qquad [\mu_{(b,u,s,t)}]
\\
& \sum_{u,d} v^{unit\_flow}_{(u,n,d,s,t)} = p^{demand}_{(n, s, t)} \quad \forall n \in node, s,t
\end{aligned}
```
This sub problem can be solved individually for each ``t``. This is pretty trivial in this small example
but if we consider a single t to be a single rolling horizon instead,
decoupling the investment variables means that each rolling horizon can be solved individually
rather than having to solve the entire model horizon as a single problem.

``\mu_{(b,u,s,t)}`` is the marginal value of the capacity constraint for benders iteration ``b``
and can be interpreted as the decrease in the objective function for an additional MW of flow from unit ``u``
(in scenario ``s`` at time ``t``).
Thus, an upper bound on the sub problem objective function is obtained as follows:

```math
sp\_obj_{b} + \sum_{u,n,d,s,t} \mu_{(b,u,s,t)} \cdot p^{unit\_capacity}_{(u,n,d,s,t)} 
\cdot \left(v^{units\_invested\_available}_{(u,s,t)} - p^{units\_invested\_available}_{(b,u,s,t)}\right)
```

The above is added to the master problem for the next iteration as a new constraint, called a Benders cut,
thus becoming:

```math
\begin{aligned}
min & \\
& \sum_{u,s,t} p^{unit\_investment\_cost}_{(u,s,t)} \cdot v^{units\_invested}_{(u,s,t)}
+ v^{sp\_objective} \\

s.t. & \\

& v^{sp\_objective} \geq sp\_obj_{b} \\
& \quad + \sum_{u,n,d,s,t} \mu_{(b,u,s,t)} \cdot p^{unit\_capacity}_{(u,n,d,s,t)}
\cdot \left(v^{units\_invested\_available}_{(u,s,t)} - p^{units\_invested\_available}_{(b,u,s,t)}\right) \quad \forall b \\
\end{aligned}
```
Note the benders cuts are added as inequalities because they represent an upper bound on the value
we are going to get for the sub problem objective function by adjusting the master problem variables
in that benders iteration.
If we consider the example of renewable generation - because it's marginal cost is zero,
on the first benders iteration, it could look like there would be a lot of value in increasing the capacity
because of the marginal values from the sub problems.
However, when the capacity variables are increased accordingly and curtailment occurs in the sub-problems,
the marginal values will be zero when curtailment occurs and so,
other resources may become optimal in subsequent iterations.

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
& v^{sp\_objective} \\
& \geq \\
& p^{sp\_obj}_{(b)} + \\
& \sum_{u,s,t} p^{units\_invested\_available\_mv}_{(b,u,s,t)}
\cdot \left( v^{units\_invested\_available}_{(u,s,t)} - p^{units\_invested\_available}_{(u,s,t)} \right) \\
& + \sum_{c,s,t} p^{connections\_invested\_available\_mv}_{(b,c,s,t)}
\cdot \left( v^{connections\_invested\_available}_{(c,s,t)} - p^{connections\_invested\_available}_{(c,s,t)} \right) \\
& + \sum_{n,s,t} p^{storages\_invested\_available\_mv}_{(b,n,s,t)}
\cdot \left( v^{storages\_invested\_available}_{(n,s,t)} - p^{storages\_invested\_available}_{(n,s,t)} \right) \\
\end{aligned}
```

where


- ``p^{sp\_obj}_{(b)}`` is the sub problem objective function value in benders iteration ``b``,
- ``p^{units\_invested\_available\_mv}`` is the reduced cost of the [units\_invested\_available](@ref) fixed
  sub-problem variable, representing the reduction in operating costs possible from an investment in a [unit](@ref)
  of this type,  
- ``p^{connections\_invested\_available\_mv}`` is the reduced cost of the [connections\_invested\_available](@ref)
  fixed sub-problem variable, representing the reduction in operating costs possible from an investment in a
  [connection](@ref) of this type,  
- ``p^{storages\_invested\_available\_mv}`` is the reduced cost of the [storages\_invested\_available](@ref) fixed
  sub-problem variable, representing the reduction in operating costs possible from an investment in a storage
  [node](@ref) of this type,  
- ``p^{units\_invested\_available}`` is the value of the fixed sub problem variable
  [units\_invested\_available](@ref) in benders iteration ``b``,  
- ``p^{connections\_invested\_available}`` is the value of the fixed sub problem variable
  [connections\_invested\_available](@ref) in benders iteration ``b`` and  
- ``p^{storages\_invested\_available}`` is the value of the fixed sub problem variable
  [storages\_invested\_available](@ref) in benders iteration ``b``

