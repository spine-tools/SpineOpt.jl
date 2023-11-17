# Constraints

## Balance constraint

### [Nodal balance](@id constraint_nodal_balance)

@@add_constraint_nodal_balance!

The constraint consists of the [node injections](@ref constraint_node_injection) and the net [connection\_flow](@ref)s.

### [Node injection](@id constraint_node_injection)

@@add_constraint_node_injection!

### [Node state capacity](@id constraint_node_state_capacity)

@@add_constraint_node_state_capacity!

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

##### [Bound on online units](@id constraint_units_on)

@@add_constraint_units_on!

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

#### [Unit piecewise incremental heat rate](@id constraint_unit_pw_heat_rate)

@@add_constraint_unit_pw_heat_rate!

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

#### [Nodebased lossless DC power flow](@id nodal-lossless-DC)

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
