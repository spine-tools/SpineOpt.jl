Connection: The [investment\_variable\_type](@ref) parameter represents the *type* of the 
[connections\_invested\_available](@ref) decision variable. The default value, `variable_type_integer`, means that only 
integer factors of the [connection\_capacity](@ref) can be invested in. The value `variable_type_continuous` means that 
any fractional factor can also be invested in. The value `variable_type_binary` means that only a factor of 1 or zero 
are possible.

Unit: Within an investments problem `investment_variable_type` determines the [unit](@ref) investment decision variable 
type. Since the `unit_flow`s will be limited to the product of the investment variable and the corresponding 
[unit\_capacity](@ref) for each `unit_flow` and since [investment\_count\_max\_cumulative](@ref) represents the upper 
bound of the investment decision variable, `investment_variable_type` thus determines what the investment decision 
represents. If [investment\_variable\_type](@ref) is integer or binary, then [investment\_count\_max\_cumulative](@ref) 
represents the maximum number of discrete units that may be invested. If [investment\_variable\_type](@ref) is 
continuous, `investment_count_max_cumulative` is more analagous to a capacity with [unit\_capacity](@ref) being 
analagous to a scaling parameter. For example, if `investment_variable_type` = `integer`, 
`investment_count_max_cumulative` = 4 and `unit_capacity` for a particular `unit_flow` = 400 MW, then the investment 
decision is how many 400 MW units to build. If `investment_variable_type` = continuous, 
`investment_count_max_cumulative` = 400 and `unit_capacity` for a particular `unit_flow` = 1 MW, then the investment 
decision is how much capacity if this particular unit to build. Finally, if `investment_variable_type` = `integer`, 
`investment_count_max_cumulative` = 10 and `unit_capacity` for a particular `unit_flow` = 50 MW, then the investment 
decision is many 50MW blocks of capacity of this particular unit to build.

See also [Investment Optimization](@ref) and [investment\_count\_max\_cumulative](@ref)
