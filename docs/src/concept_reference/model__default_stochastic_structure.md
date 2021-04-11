The [model\_\_default\_stochastic\_structure](@ref) relationship can be used to set a [model](@ref)-wide default
for the [node\_\_stochastic\_structure](@ref) and [units\_on\_\_stochastic\_structure](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [node\_\_stochastic\_structure](@ref) or [units\_on\_\_stochastic\_structure](@ref)
relationships take priority over the [model\_\_default\_stochastic\_structure](@ref) relationship.