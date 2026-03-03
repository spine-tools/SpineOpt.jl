The [flow\_limits\_fix](@ref) parameter fixes the value of the [unit\_flow](@ref) variable to the provided value, if the parameter is defined.

Common uses for the parameter include e.g. providing initial values for the [unit\_flow](@ref) variable,
by fixing the value on the first modelled time step *(or the value before the first modelled time step)*
using a `TimeSeries` type parameter value with an appropriate timestamp.
Due to the way *SpineOpt* handles `TimeSeries` data,
the [unit\_flow](@ref) variable is only fixed for time steps with defined [flow\_limits\_fix](@ref) parameter values.

Other uses can include e.g. a constant or time-varying **exogenous** commodity flow from or to a unit.
