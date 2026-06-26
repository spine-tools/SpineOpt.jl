Defines the type of the variables used for investment decisions.
Setting [investment\_variable\_type](@ref) = `none` can be used to disable investments
regardless of [investment\_count\_max\_cumulative](@ref).
See the following for more details for connections and units, respectively.

Connection: The [investment\_variable\_type](@ref) parameter represents the *type* of the 
[connections\_invested\_available](@ref var_connections_invested_available) decision variable.
The default value, `linear`, means that any arbitrary fraction of [capacity\_per\_connection](@ref) can be invested in.
Meanwhile, `integer` and `binary` limit these according to their names, respectively.

Unit: Within an investment problem [investment\_variable\_type](@ref) determines the [unit](@ref) investment decision variable type.
Since the [unit\_flow](@ref var_unit_flow)s will be limited to the product of the investment variable and the corresponding 
[capacity\_per\_unit](@ref) for each [unit\_flow](@ref var_unit_flow) and since [investment\_count\_max\_cumulative](@ref) represents the upper 
bound of the investment decision variable, [investment\_variable\_type](@ref) thus determines what the investment decision represents.
If [investment\_variable\_type](@ref) is `integer` or `binary`, then [investment\_count\_max\_cumulative](@ref)
represents the maximum number of discrete units that may be invested.
If [investment\_variable\_type](@ref) is `linear` (default), [investment\_count\_max\_cumulative](@ref) is more analogous to a capacity with [capacity\_per\_unit](@ref) being analogous to a scaling parameter.

For example, if [investment\_variable\_type](@ref) = `integer`, 
[investment\_count\_max\_cumulative](@ref) = 4 and [capacity\_per\_unit](@ref) for a particular [unit\_flow](@ref var_unit_flow) = 400 MW, then the investment 
decision is how many 400 MW units to build. If [investment\_variable\_type](@ref) = linear, 
[investment\_count\_max\_cumulative](@ref) = 400 and [capacity\_per\_unit](@ref) for a particular [unit\_flow](@ref var_unit_flow) = 1 MW, then the investment 
decision is how much capacity if this particular unit to build. Finally, if [investment\_variable\_type](@ref) = `integer`, 
[investment\_count\_max\_cumulative](@ref) = 10 and [capacity\_per\_unit](@ref) for a particular [unit\_flow](@ref var_unit_flow) = 50 MW, then the investment 
decision is many 50MW blocks of capacity of this particular unit to build.

See also [Investment Optimization](@ref) and [investment\_count\_max\_cumulative](@ref)
