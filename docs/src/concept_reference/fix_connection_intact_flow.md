The [fix\_connection\_intact\_flow](@ref) parameter can be used to fix the values of the
[connection\_intact\_flow](@ref) variable to preset values.
If set to a `Scalar` type value, the [connection\_intact\_flow](@ref) variable is fixed to that value
for all time steps and [stochastic\_scenario](@ref)s.
Values for individual time steps can be fixed using `TimeSeries` type values.