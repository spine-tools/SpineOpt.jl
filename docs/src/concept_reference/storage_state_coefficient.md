The [storage\_state\_coefficient](@ref) parameter acts as a coefficient for the `node_state` variable
in the [node injection constraint](@ref constraint_node_injection).
Essentially, it tells how the `node_state` variable should be treated in relation to the commodity flows
and [demand](@ref), and can be used for e.g. scaling or unit conversions.
For most use-cases a [storage\_state\_coefficient](@ref) parameter value of `1.0` should suffice,
e.g. having a MWh storage connected to MW flows in a model with hour as the basic unit of time.

Note that in order for the [storage\_state\_coefficient](@ref) parameter to have an impact,
the [node](@ref) must first have a `node_state` variable to begin with,
defined using the [storage\_activate](@ref) parameter.
By default, the [storage\_state\_coefficient](@ref) is set to zero as a precaution,
so that the user always has to set its value explicitly for it to have an impact on the model.
