The [stochastic\_structure](@ref) is the key component of the scenario-based [Stochastic Framework](@ref)
in *SpineOpt.jl*, and essentially represents a group of [stochastic\_scenario](@ref)s with set [Parameters](@ref).
The [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship defines which [stochastic\_scenario](@ref)s
are included in which [stochastic\_structure](@ref)s, and the [weight\_relative\_to\_parents](@ref) and
[stochastic\_scenario\_end](@ref) [Parameters](@ref) define the exact shape and impact of the
[stochastic\_structure](@ref), along with the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref)
relationship.

The main reason as to why [stochastic\_structure](@ref)s are so important is, that they act as handles connecting the
[Stochastic Framework](@ref) to the modelled system.
This is handled using the [Structural relationship classes](@ref) e.g. [node\_\_stochastic\_structure](@ref),
which define the [stochastic\_structure](@ref) applied to each `object` describing the modelled system.
Connecting each system `object` to the appropriate [stochastic\_structure](@ref) individually can be a bit bothersome
at times, so there are also a number of convenience [Meta relationship classes](@ref) like the
[model\_\_default\_stochastic\_structure](@ref), which allow setting [model](@ref)-wide defaults to be used whenever
specific definitions are missing.