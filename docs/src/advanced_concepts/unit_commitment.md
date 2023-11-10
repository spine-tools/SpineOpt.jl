# Unit commitment

To incorporate technical detail about (clustered) unit-commitment statuses of units, the online, started and shutdown status of units can be tracked and constrained in SpineOpt.
In the following, relevant relationships and parameters are introduced and the general working principle is described.

## Key concepts for unit commitment
Here, we briefly describe the key concepts involved in the representation of (clustered) unit commitment models:

- [units\_on](@ref Variables) is an optimization variable that holds information about the on- or offline status of a unit. Unit commitment restrictions will govern how this variable can change through time.

- [units\_on\_\_temporal\_block](@ref) is a relationship linking the `units_on` variable of this unit to a specific [temporal\_block](@ref) object. The temporal block holds information on the temporal scope and resolution for which the variable should be optimized.

- [online\_variable\_type](@ref) is a method parameter and can take the values `unit_online_variable_type_binary`, `unit_online_variable_type_integer`, `unit_online_variable_type_linear`. If the binary value is chosen, the units status is modelled as a binary (classic UC). For clustered unit commitment units, the integer type is applicable. Note that if the parameter is not defined, the default will be linear. If the units status is not crucial, this can reduce the computational burden.

- [number\_of\_units](@ref) defines how many units of a certain unit type are available. Typically this parameter takes a binary (UC) or integer (clustered UC) value. To avoid confusion the following distinction will be made in this document:  `unit` will be used to identify a Spine unit object, which can have multiple `members`. Together with the `unit_availability_factor`, this will determine the maximum number of members that can be online at any given time. (Thus restricting the `units_on` variable). The default value for this parameter is ``1``. It is possible to allow the model to increase the `number_of_units` itself, through [Investment Optimization](@ref)

- [unit\_availability\_factor](@ref): (number value or time series). Is the fraction of the time that this unit is considered to be available, by acting as a multiplier on the capacity. A time series can be used to indicate the intermittent character of renewable generation technologies.

- [min\_up\_time](@ref): (duration value). Sets the minimum time that a unit has to stay online after a startup. Inclusion of this parameter will trigger the creation of the constraint on [Minimum up time (basic version)](@ref constraint_min_up_time)

- [min\_down\_time](@ref): (duration value). Sets the minimum time that a unit has to stay offline after a shutdown. Inclusion of this parameter will trigger the creation of the constraint on [Minimum down time (basic version)](@ref constraint_min_down_time)

- [minimum\_operating\_point](@ref): (number value) limits the minimum value of the `unit_flow` variable for a unit which is currently online. Inclusion of this parameter will trigger the creation of the [Constraint on minimum operating point](@ref constraint_minimum_operating_point)

- [start\_up\_cost](@ref): "number value". Cost associated with starting up a unit.
- [shut\_down\_cost](@ref): "number value". Cost associated with shutting down a unit.

## Illustrative unit commitment examples

### Step 1: defining the number of members of a unit type
A spine unit can represent multiple members. This can be incorporated in a model by setting the [number\_of\_units](@ref) parameter to a specific value. For example, if we define a single unit in a model as follows:
* `unit_1`
  * `number_of_units`: 2
And we link the unit to a certain `node_1` with a [unit\_\_to\_node](@ref) relationship.
* `unit_1_to__node_1`

The single Spine unit defined here, now represents two members. This means that a single [unit_flow](@ref Variables) variable will be created for this unit, but the restrictions as imposed by the [Ramping](@ref) and [Reserves](@ref) framework will be adapted to reflect the fact that there are two members present, thus doubling the total capacity.

### Step 2: choosing the online\_variable\_type
Next, we have to decide the [online\_variable\_type](@ref) for this unit, which will restrict the kind of values that the [units_on](@ref Variables) variable can take. This basically comes down to deciding if we are working in a classical UC framework (`unit_online_variable_type_binary`), a clustered UC framework (`unit_online_variable_type_integer`), or a relaxed clustered UC framework (`unit_online_variable_type_linear`), in which a non-integer number of units can be online.

The classical UC framework can only be applied when the `number_of_units` equals 1.

### Step 3: imposing a minimum operating point
The output of an online unit to a specific node can be restricted to be above a certain minimum by choosing a value for the [minimum\_operating\_point](@ref) parameter. This parameter is defined for the [unit\_\_to\_node](@ref) relationship, and is given as a fraction of the [unit_capacity](@ref). If we continue with the example above, and define the following objects, relationships, and parameters:

* `unit_1`
  * `number_of_units`: 2
  * `unit_online_variable_type`: "unit\_online\_variable\_type\_integer"
* `unit_1_to__node_1`
  * `minimum_operating_point`: 0.2
  * `unit_capacity`: 200
It can be seen that in this case the [unit_flow](@ref Variables) form `unit_1` to `node_1` must for any timestep ``t`` be larger than ``units\_on(t) * 0.2 * 200``

### Step 4: imposing a minimum up or down time
Spine units can also be restricted in their commitment status with minimum up- or down times by choosing a value for the [min\_up\_time](@ref) or [min\_down\_time](@ref) respectively. These parameters are defined for the [unit](@ref) object, and should be duration values. We can continue the example and add a minimum up time for the unit:

* `unit_1`
  * `number_of_units`: 2
  * `unit_online_variable_type`: "unit\_online\_variable\_type\_integer"
  * `min_up_time`: 2h
* `unit_1_to__node_1`
  * `minimum_operating_point`: 0.2
  * `unit_capacity`: 200

Whereas the `units_on` variable was restricted (before inclusion of the `min_up_time` parameter) to be smaller than or equal to the `number_of_units` for any timestep ``t``, it now has to be smaller than or equal to the `number_of_units` decremented with the [units\_started\_up](@ref Variables) summed over the timesteps that include `t - min_up_time`. This implies that a unit which has started up, has to stay online for at least the `min_up_time`

To consider a simple example let's assume that we have a model with a resolution of 1h. Suppose that before `t`, there is no member of the unit online and in timestep `t -> t + 1h`, one member starts up. Another member starts up in timestep `t + 1h \-> t + 2h`. The first startup, along with the minimum up time of 2 hours implies that the `units_on` variable of this unit has now changed to ``1`` in timestep `t -> t + 1h` and can not go back to ``0`` in timestep `t-> t + 1h -> t + 2h`. The second startup further restricts the number of units that are allowed to be online, it can be seen that the following restrictions apply when both startups are combined with the minimum up time of 2h:

* `t-> t + 1h` : `` units\_on = 1 ``
* `t + 1h -> t + 2h`: `` units\_on = 2``
* `t + 2h-> t + 3h`: `` units\_on \in {1,2} ``
* `t + 3h-> t + 4h`: `` units\_on \in {0,1,2} ``

The minimum down time restrictions operate in very much the same way, they simply impose that units that have been shut down, have to stay offline for the chosen period of time.

### Step 5: allocationg a cost to startups or shutdowns

Costs can be allocated to startups or shutdowns by choosing a value for the [start\_up\_cost](@ref) or [shut\_down\_cost](@ref) respectively.

### Step 6: defining unit availabilities

By defining a [unit\_availability\_factor](@ref), the fact that typical members are not available all the time can be reflected in the model.

Typically, units are not available ``100``% of the time, due to scheduled maintenance, unforeseen outages, or other things. This can be incorporated in the model by setting the `unit_availability_factor` to a fractional value. For each timestep in the model, an upper bound is then imposed on the `units_on` variable, equal to `number_of_units` ``*`` `unit_availability_factor`. This parameter can not be used when the `online_variable_type` is binary. It should also be noted that when the `online_variable_type` is of integer type, the aforementioned product must be integer as well, since it will determine the value of the `units_available` parameter which is restricted to integer values. The default value for this parameter is ``1``.

The `unit_availability_factor` can also be taken as a timeseries. By allowing a different availability factor for each timestep in the model, it can perfectly be used to represent intermittent technologies of which the output cannot be fully controlled.
