The [units\_on\_\_stochastic\_structure](@ref) relationship defines the [stochastic\_structure](@ref)
used by the [units\_on](@ref) variable.
Essentially, this relationship permits defining a different [stochastic\_structure](@ref) for the online decisions
regarding the [units\_on](@ref) variable,
than what is used for the production [unit\_flow](@ref) variables.
A common use-case is e.g. using only one [units\_on](@ref) variable
across multiple [stochastic\_scenario](@ref)s for the [unit\_flow](@ref) variables.
Note that only one [units\_on\_\_stochastic\_structure](@ref) relationship can be defined per [unit](@ref) per [model](@ref),
as interpreted by the [units\_on\_\_stochastic\_structure](@ref) and [model\_\_stochastic\_structure](@ref)
relationships.

The [units\_on\_\_stochastic\_structure](@ref) relationship uses the [model\_\_default\_stochastic\_structure](@ref)
relationship if not specified.