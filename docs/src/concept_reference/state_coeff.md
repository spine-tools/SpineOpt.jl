The [state\_coeff](@ref) parameter acts as a coefficient for the `node_state` variable
in the [node injection constraint](@ref constraint_node_injection).
Essentially, it tells how the `node_state` variable should be treated in relation to the [commodity](@ref) flows
and [demand](@ref), and can be used for e.g. scaling or unit conversions.
For most use-cases a [state\_coeff](@ref) parameter value of `1.0` should suffice,
e.g. having a MWh storage connected to MW flows in a model with hour as the basic unit of time.

Note that in order for the [state\_coeff](@ref) parameter to have an impact,
the [node](@ref) must first have a `node_state` variable to begin with,
defined using the [has\_state](@ref) parameter.
By default, the [state\_coeff](@ref) is set to zero as a precaution,
so that the user always has to set its value explicitly for it to have an impact on the model.
