Connection: The [investment\_count\_fix\_cumulative](@ref) parameter represents a *forced* connection investment.
In other words, it is the fix value of the [connections\_invested\_available](@ref) variable.

Unit: The `investment_count_fix_cumulative` parameter is used primarily to fix the value of the `units_invested_available`
variable which represents the unit investment decision variable and how many candidate units are invested-in and
available at the corresponding node, time step and stochastic scenario. Used also in the decomposition framework to
communicate the value of the master problem solution variables to the operational sub-problem.

See also [Investment Optimization](@ref), [investment\_count\_max\_cumulative](@ref) and
[investment\_variable\_type](@ref)
