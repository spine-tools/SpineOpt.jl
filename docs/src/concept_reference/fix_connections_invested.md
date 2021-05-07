The [fix\_connections\_invested](@ref) parameter can be used to fix the values of the
[connections\_invested](@ref) variable to preset values.
If set to a `Scalar` type value, the [connections\_invested](@ref) variable is fixed to that value
for all time steps and [stochastic\_scenario](@ref)s.
Values for individual time steps can be fixed using `TimeSeries` type values.

See [Investment Optimization](@ref) for more information about the investment framework in *SpineOpt.jl*.