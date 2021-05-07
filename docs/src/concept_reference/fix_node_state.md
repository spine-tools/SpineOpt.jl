The [fix\_node\_state](@ref) parameter simply fixes the value of the `node_state` variable to the provided value,
if one is found.
Common uses for the parameter include e.g. providing initial values for `node_state` variables,
by fixing the value on the first modelled time step *(or the value before the first modelled time step)*
using a `TimeSeries` type parameter value with an appropriate timestamp.
Due to the way *SpineOpt* handles `TimeSeries` data,
the `node_state` variables are only fixed for time steps with defined [fix\_node\_state](@ref) parameter values.