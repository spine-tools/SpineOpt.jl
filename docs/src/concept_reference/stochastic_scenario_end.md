The [stochastic\_scenario\_end](@ref) is a `Duration`-type parameter,
defining when a [stochastic\_scenario](@ref) ends relative to the start of the current optimization.
As it is a parameter for the [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship, different
[stochastic\_structure](@ref)s can have different values for the same [stochastic\_scenario](@ref), making it
possible to define slightly different [stochastic\_structure](@ref)s using the same [stochastic\_scenario](@ref)s.
See the [Stochastic Framework](@ref) section for more information about how different [stochastic\_structure](@ref)s
interact in *SpineOpt.jl*.

When a [stochastic\_scenario](@ref) ends at the point in time defined by the [stochastic\_scenario\_end](@ref)
parameter, it spawns its children according to the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref)
relationship.
Note that the children will be inherently assumed to belong to the same [stochastic\_structure](@ref) their parent
belonged to, even without explicit [stochastic\_structure\_\_stochastic\_scenario](@ref) relationships!
Thus, you might need to define the [weight\_relative\_to\_parents](@ref) parameter for the children.

If no [stochastic\_scenario\_end](@ref) is defined, the [stochastic\_scenario](@ref) is assumed to go on indefinitely.