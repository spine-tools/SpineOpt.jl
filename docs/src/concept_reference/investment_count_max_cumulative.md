Connection: The [investment\_count\_max\_cumulative](@ref) parameter denotes the possibility of investing on a certain 
[connection](@ref). The default value of `nothing` means that the [connection](@ref) can't be invested in, because it's 
already in operation. An integer value represents the maximum investment possible at any point in time, as a factor of 
the [capacity\_per\_connection](@ref). In other words, [investment\_count\_max\_cumulative](@ref) is the upper bound of the 
[connections\_invested\_available](@ref var_connections_invested_available) variable.

Unit: Within an investments problem [investment\_count\_max\_cumulative](@ref) determines the upper bound on the [unit](@ref) 
investment decision variable in constraint [units\_invested\_available](@ref var_units_invested_available). In [the unit flow capacity constraint](@ref constraint_unit_flow_capacity) the maximum 
[unit\_flow](@ref var_unit_flow) will be the product of the [units\_invested\_available](@ref var_units_invested_available) and the corresponding [capacity\_per\_unit](@ref). Thus, 
the interpretation of [investment\_count\_max\_cumulative](@ref) depends on [investment\_variable\_type](@ref) which determines 
the [unit](@ref) investment decision variable type. If [investment\_variable\_type](@ref) is integer or binary, then 
[investment\_count\_max\_cumulative](@ref) represents the maximum number of discrete units that may be invested in. If 
[investment\_variable\_type](@ref) is linear, [investment\_count\_max\_cumulative](@ref) is more analogous to a maximum 
storage capacity. Note that [investment\_count\_max\_cumulative](@ref) is the main investment switch and setting a value other 
than none/nothing triggers the creation of the investment variable for the [unit](@ref). Note that a value of zero will 
still trigger the variable creation but its value will be fixed to zero. This can be useful if an inspection of the 
related dual variables will yield the value of this resource.

See also [Investment Optimization](@ref) and [investment\_variable\_type](@ref)
