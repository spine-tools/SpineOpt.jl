The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship defines how the individual
[stochastic\_scenario](@ref)s are related to each other, forming what is referred to as the
*stochastic direct acyclic graph (DAG)* in the [Stochastic Framework](@ref) section.
It acts as a sort of basis for the [stochastic\_structure](@ref)s, but doesn't contain any [Parameters](@ref)
necessary for describing how it relates to the [Temporal Framework](@ref) or the [Objective function](@ref).

The [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship and the *stochastic DAG* it forms
are crucial for [Constraint generation with stochastic path indexing](@ref).
Every finite *stochastic DAG* has a limited number of unique ways of traversing it, called *full stochastic paths*,
which are used when determining how many different constraints need to be generated over time periods where
[stochastic\_structure](@ref)s branch or converge, or when generating constraints involving different
[stochastic\_structure](@ref)s.
See the [Stochastic Framework](@ref) section for more information.