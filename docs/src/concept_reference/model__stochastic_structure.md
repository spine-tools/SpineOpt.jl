The [model\_\_stochastic\_structure] relationship defines which [stochastic\_structure](@ref)s
are active in which [model](@ref)s.
Essentially, this relationship allows for e.g. attributing multiple [node\_\_stochastic\_structure](@ref)
relationships for a single [node](@ref), and switching between them in different [model](@ref)s.
Any [stochastic\_structure](@ref) in the [model\_\_default\_stochastic\_structure](@ref) relationship
is automatically assumed to be active in the connected [model](@ref),
so there's no need to include it in [model\_\_stochastic\_structure] separately.