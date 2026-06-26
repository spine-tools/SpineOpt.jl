The [flow\_limits\_fix\_intact](@ref) parameter can be used to fix the values of the
[connection\_intact\_flow](@ref var_connection_intact_flow) variable to preset values.
If set to a `Scalar` type value, the [connection\_intact\_flow](@ref var_connection_intact_flow) variable is fixed to that value
for all time steps and [stochastic\_scenario](@ref)s.
Values for individual time steps can be fixed using `TimeSeries` type values.