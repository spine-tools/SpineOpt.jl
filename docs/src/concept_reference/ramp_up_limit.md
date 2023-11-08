The definition of the `ramp_up_limit` parameter limits the maximum increase in the [unit\_flow](@ref) over a period of time of one [duration\_unit](@ref) whenever the unit is online.

It can be defined for [unit__to_node](@ref) or [unit__from_node](@ref) relationships, as well as their counterparts for node groups. It will then impose restrictions on the `unit_flow` variables that indicate flows between the two members of the relationship for which the parameter is defined. The parameter is given as a fraction of the [unit\_capacity](@ref) parameter. When the parameter is not specified, the limit will not be imposed, which is equivalent to choosing a value of 1.

For a more complete description of how ramping restrictions can be implemented, see [Ramping](@ref).
