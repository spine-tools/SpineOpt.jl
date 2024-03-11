# Ramping

To enable the representation of units with a high level of technical detail, the ramping capability of units can be constrained in SpineOpt. This means that the user has the freedom to impose restrictions on the change in the output (or input) of units over time, for online (spinning) units, units starting up and units shutting down. In this section, the concept of ramps in SpineOpt will be introduced.

## Relevant objects, relationships and parameters

Everything that is related to ramping is defined in parameters of either the [unit\_\_to\_node](@ref) or [unit\_\_from\_node](@ref) relationship (where the [node](@ref) can be a group). Generally speaking, the ramping constraints will impose restrictions on the change in the [unit\_flow](@ref) variable between two consecutive timesteps.

All parameters that limit the ramping abilities of a unit are expressed as a fraction of the unit capacity. This means that a value of 1 indicates the full capacity of a unit.

The discussion here will be conceptual. For the mathematical formulation the reader is referred to the [Ramping constraints](@ref)

### Constraining spinning up and down ramps
 * [ramp\_up\_limit](@ref) : limit the maximum increase in the `unit_flow` variable when the unit is online, over a period of time equal to the [duration\_unit](@ref). The parameter is given as a fraction of the [unit\_capacity](@ref). Inclusion of this parameter will trigger the creation of the [Constraint on spinning upwards ramp](@ref constraint_ramp_up)
 * [ramp\_down\_limit](@ref) : limit the maximum decrease in the `unit_flow` variable when the unit is online, over a period of time equal to the [duration\_unit](@ref). The parameter is given as a fraction of the [unit\_capacity](@ref) parameter. Inclusion of this parameter will trigger the creation of the [Constraint on spinning downward ramps](@ref constraint_ramp_down)

### Constraining start up and shut down ramps
 * [start\_up\_limit](@ref) : limit the maximum increase in the `unit_flow` variable when the unit is starting up. The parameter is given as a fraction of the [unit\_capacity](@ref) parameter. Inclusion of this parameter will trigger the creation of the [Constraint on spinning upwards ramp](@ref constraint_ramp_up)
 * [shut\_down\_limit](@ref) : limit the maximum decrease in the `unit_flow` variable when the unit is shutting down. The parameter is given as a fraction of the [unit\_capacity](@ref) parameter. Inclusion of this parameter will trigger the creation of the [Constraint on spinning downward ramps](@ref constraint_ramp_down)

## General principle and example use cases
The general principle of the Spine modelling ramping constraints is that all of these parameters can be defined separately for each unit. This allows the user to incorporate different units (which can either represent a single unit or a technology type) with different flexibility characteristics.

It should be noted that it is perfectly possible to omit all of the ramp constraining parameters mentioned above, or to specify only some of them. Anything that is omitted is interpreted as if it shouldn't be constrained. For example, if you only specify [start\_up\_limit](@ref) and [ramp\_down\_limit](@ref), then only the flow *increase* during *start up* and the flow *decrease* during *online* operation will be constrained (but not any other flow increase or decrease).

### Illustrative examples
#### Step 1: Simple case of unrestricted unit
When none of the ramping parameters mentioned above are specified, the unit is considered to have full ramping flexibility. This means that over any period of time, its flow can be any value between 0 and its capacity, regardless of what the flow of the unit was in previous timesteps, and regardless of the on- or offline status of the unit in previous timesteps (while still respecting, of course, the [Unit commitment](@ref) restrictions that are defined for this unit). This is equivalent to specifying the following:
* `shut_down_limit` : 1
* `start_up_limit` : 1
* `ramp_up_limit` : 1
* `ramp_down_limit` : 1

#### Step 2: Spinning ramp restriction
A unit which is only restricted in spinning ramping can be created by changing the `ramp_up/down_limit` parameters:

 * `ramp_up_limit` : **0.2**
 * `ramp_down_limit` : **0.4**

 This parameter choice implies that the unit flow cannot increase more than ``0.2  * 200`` and cannot decrease more than ``0.4 * 200`` over a period of time equal to 'one' [duration\_unit](@ref). For example, when the unit is running at an output of ``100`` in some timestep ``t``, its output for the next 'one' [duration\_unit](@ref) must be somewhere in the interval ``[20, 140]`` - unless it shuts down completely.

#### Step 3: Shutdown restrictions

 By specifying the parameter `shut_down_limit`, an additional restriction is imposed on the maximum flow of the unit at the moment it goes offline:

 * `shut_down_limit` : **0.5**
 * `minimum_operating_point` : **0.3**

 When the unit goes offline in a given timestep ``t``, the output of the unit must be below ``0.5 * 200 = 100``  in the timestep *right before* that ``t`` (and of course, above ``0.3 * 200 = 60`` - the minimum operating point).

#### Step 4: Startup restrictions

 The start up restrictions are very similar to the shut down restrictions, but of course apply to units that are starting up. THey are activated by specifying `start_up_limit`:

 * `start_up_limit` : **0.4**
 * `minimum_operating_point` : **0.2**

When the unit goes online in a given timestep ``t``, its output will be restricted to the interval ``[40, 80]``.


## Using node groups to constraint aggregated flow ramps

SpineOpt allows the user to constrain ramping abilities of units that are linked to multiple nodes by defining node groups.
When a node group is defined, ramping restrictions can be imposed both on the group level (thus for the unit as a whole) as well as for the individual nodes.
For example, let's assume that we have one unit and two nodes in a model. The unit is linked via `unit__to_node` relationships to each node individually, and on top of that, it is linked to a node group containing both nodes.

If, for example a `ramp_up_limit` is defined for the node group, the sum of upward ramping of the two nodes will be restricted by this parameter.
However, it is still possible to limit the individual flows to the nodes as well. Let's say that our unit is capable of ramping up by 20% of its capacity and down by 40%. We might want to impose tighter restrictions for the flows towards one of the nodes (e.g. because the energy has to be provided in a shorter time than the [duration\_unit](@ref)). One can then simply define an additional parameter for that `unit__to_node` relationship as follows.

* `ramp_up_limit`  : 0.15

Which now restricts the flow of the unit into that node to 15% of its capacity.

**Please note that by default, node groups are balanced in the same way as individual nodes.**
So if you're using node groups for the sole purpose of constraining flow ramps, you should set the balance type of the group to `balance_type_none`.


## [Ramping with reserves](@id ramping-reserves-illustrative-example)

If a unit is set to provide reserves, then it should be able to provide that reserve within one [duration\_unit](@ref).
For this reason, reserve provision must be accounted for within ramp constraints.
Please see [Reserves](@ref) for details on how to setup a `node` as a reserve.

### Examples

Let's assume that we have one unit and two nodes in a model, one for reserves and one for regular demand. The unit is then linked by the `unit__to_node` relationships to both the reserves and regular demand node.

#### Spinning ramp restriction

The unit can be restricted in spinning ramping by defining the `ramp_up/down_limit` parameters in the `unit__to_node` relationship for the regular demand node:

 * `ramp_up_limit`      : **0.2**
 * `ramp_down_limit`    : **0.4**

 This parameter choice implies that the unit's flow to the regular demand node cannot increase more than ``0.2  * 200 - upward\_reserve\_demand`` or decrease more than ``0.4 * 200 - downward\_reserve\_demand`` over one [duration\_unit](@ref). For example, when the unit is running at an output of ``100`` and there is an upward reserve demand of ``10``, then its output over the next [duration\_unit](@ref) must be somewhere in the interval ``[20, 130]``.

 It can be seen in this example that the demand for reserves is subtracted from the ramping capacity of the unit that is available for regular operation. This stems from the fact that in providing reserve capacity, the unit is expected to be able to provide the demanded reserve within one [duration\_unit](@ref) as stated above.