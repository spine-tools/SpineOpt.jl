Essentially, a [stochastic\_scenario](@ref) is a label for an alternative period of time,
describing one possibility of what might come to pass.
They are the basic building blocks of the scenario-based [Stochastic Framework](@ref) in *SpineOpt.jl*,
but aren't really meaningful on their own.
Only when combined into a [stochastic\_structure](@ref) using the [stochastic\_structure\_\_stochastic\_scenario](@ref)
and [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationships,
along with [Parameters](@ref) like the [weight\_relative\_to\_parents](@ref) and [stochastic\_scenario\_end](@ref),
they become meaningful.