The [units\_on\_\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
used by the `units_on` [variable](@ref Variables).
Essentially, this relationship permits defining a different [stochastic\_structure](@ref) for the online decisions
regarding the `units_on` [variable](@ref Variables),
than what is used for the production `unit_flow` [variables](@ref Variables).
A common use-case is e.g. using only one `units_on` [variable](@ref Variables)
across multiple [stochastic\_scenario](@ref)s for the `unit_flow` [variables](@ref Variables).

The [units\_on\_\_stochastic\_structure](@ref) relationship uses the [model\_\_default\_stochastic\_structure](@ref)
relationship if not specified.