# Unit commitment

To incorporate technical detail about (clustered) unit-commitment statuses of units, the online, started and shutdown status of units can be tracked and constrained in SpineOpt.
In the following, relevant relationships and parameters are introduced and the general working principle is described.

## Key concepts for unit commitment
Here, we briefly describe the key concepts involved in the representation of (clustered) unit commitment models:

1. [units\_on](@ref Variables) is an optimization variable that holds information about the on- or offline status of a unit. Unit commitment restrictions will govern how this variable can change through time.

2. [units\_on\_\_temporal\_block](@ref) is a relationship linking the `units_on` variable of this unit to a specific [temporal\_block](@ref) object. The temporal block holds information on the temporal scope and resolution for which the variable should be optimized.

3. [online\_variable\_type](@ref) is a method parameter and can take the values "unit\_online\_variable\_type\_binary", "unit\_online\_variable\_type\_integer", "unit\_online\_variable\_type\_linear". If the binary value is chosen, the units status is modelled as a binary (classic UC). For clustered unit commitment units, the integer type is applicable. Note that if the parameter is not defined, the default will be linear. If the units status is not crucial, this can reduce the computational burden.

4. [number\_of\_units](@ref) defines how many units of a certain unit type are available. Typically this parameter takes a binary (UC) or integer (clustered UC) value. To avoid confusion the following distinction will be made in this document:  `unit` will be used to identify a Spine unit object, which can have multiple `members`. Together with the `unit_availability_factor`, this will determine the maximum number of members that can be online at any given time. (Thus restricting the `units_on` variable). The default value for this parameter is ``1``. It is possible to allow the model to increase the `number_of_units` itself, through [Investment Optimization](@ref)

5. [unit\_availability\_factor](@ref): (number value). Is the fraction of the time that this unit is considered to be available. Typically, units are not available ``100``% of the time, due to scheduled maintenance, unforeseen outages, or other things. This can be incorporated in the model by setting the `unit_availability_factor` to a fractional value. For each timestep in the model, an upper bound is then imposed on the `units_on` variable, equal to `number_of_units` ``*`` `unit_availability_factor`. This parameter can not be used when the `online_variable_type` is binary. It should also be noted that when the `online_variable_type` is of integer type, the aforementioned product must be integer as well, since it will determine the value of the `units_available` parameter which is restricted to integer values. The default value for this parameter is ``1``.

6. [min\_up\_time](@ref): (duration value). Sets the minimum time that a unit has to stay online after a startup. Inclusion of this parameter will trigger the creation of the constraint on [Minimum up time (basic version)](@ref)

7. [min\_down\_time](@ref): (duration value). Sets the minimum time that a unit has to stay offline after a shutdown. Inclusion of this parameter will trigger the creation of the constraint on [Minimum down time (basic version)](@ref)

8. [minimum\_operating\_point](@ref): (number value) limits the minimum value of the `unit_flow` variable for a unit which is currently online. Inclusion of this parameter will trigger the creation of the [Constraint on minimum operating point](@ref)

9. [start\_up\_cost](@ref): "number value". Cost associated with starting up a unit.
10. [shut\_down\_cost](@ref): "number value". Cost associated with shutting down a unit.


I feel like `units_on__temporal_block` should be added here aswell.
Also we need to add the unit status variables to the mathematical_formulation, but should probably also briefly explain them here.

Also can we change the formatting a bit? When I build the documentation, the indentations are a bit off
