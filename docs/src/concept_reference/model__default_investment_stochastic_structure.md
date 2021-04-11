The [model\_\_default\_investment\_stochastic\_structure](@ref) relationship can be used to set [model](@ref)-wide
default [unit\_\_investment\_stochastic\_structure](@ref), [connection\_\_investment\_stochastic\_structure](@ref),
and [node\_\_investment\_stochastic\_structure](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [unit\_\_investment\_stochastic\_structure](@ref),
[connection\_\_investment\_stochastic\_structure](@ref), and [node\_\_investment\_stochastic\_structure](@ref)
relationships take priority over the [model\_\_default\_investment\_stochastic\_structure](@ref) relationship.