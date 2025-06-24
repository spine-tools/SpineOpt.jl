Connection: The `investment\_count\_fix\_new` parameter can be used to fix the values of the
[connections\_invested](@ref) variable to preset values.
If set to a `Scalar` type value, the [connections\_invested](@ref) variable is fixed to that value
for all time steps and [stochastic\_scenario](@ref)s.
Values for individual time steps can be fixed using `TimeSeries` type values.

Unit: The `investment_count_fix_new` parameter is used primarily to fix the value of the `units_invested` variable which
represents the point-in-time [unit](@ref) investment decision variable and how many candidate units are invested-in in a
particular timeslice.

See also [Investment Optimization](@ref), [investment\_count\_max\_cumulative](@ref) and
[investment\_variable\_type](@ref)
