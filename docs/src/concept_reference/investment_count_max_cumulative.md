Connection: The [investment\_count\_max\_cumulative](@ref) parameter denotes the possibility of investing on a certain 
[connection](@ref). The default value of `nothing` means that the [connection](@ref) can't be invested in, because it's 
already in operation. An integer value represents the maximum investment possible at any point in time, as a factor of 
the [connection\_capacity](@ref). In other words, [investment\_count\_max\_cumulative](@ref) is the upper bound of the 
[connections\_invested\_available](@ref) variable.

Unit: Within an investments problem `investment_count_max_cumulative` determines the upper bound on the [unit](@ref) 
investment decision variable in constraint `units_invested_available`. In constraint `unit_flow_capacity` the maximum 
`unit_flow` will be the product of the `units_invested_available` and the corresponding [capacity\_per\_unit](@ref). Thus, 
the interpretation of `investment_count_max_cumulative` depends on [investment\_variable\_type](@ref) which determines 
the [unit](@ref) investment decision variable type. If [investment\_variable\_type](@ref) is integer or binary, then 
`investment_count_max_cumulative` represents the maximum number of discrete units that may be invested in. If 
[investment\_variable\_type](@ref) is continuous, `investment_count_max_cumulative` is more analagous to a maximum 
storage capacity. Note that `investment_count_max_cumulative` is the main investment switch and setting a value other 
than none/nothing triggers the creation of the investment variable for the [unit](@ref). Note that a value of zero will 
still trigger the variable creation but its value will be fixed to zero. This can be useful if an inspection of the 
related dual variables will yield the value of this resource.

See also [Investment Optimization](@ref) and [investment\_variable\_type](@ref)
