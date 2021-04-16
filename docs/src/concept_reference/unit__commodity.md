To impose a limit on the cumulative amount of commodity flows, the [max\_cum\_in\_unit\_flow\_bound](@ref)
can be imposed on a [unit\_\_commodity](@ref) relationship. This can be very helpful, e.g. if
a certain amount of emissions should not be surpased throughout the optimization.

Note that, next to the [unit\_\_commodity](@ref) relationship, also the nodes connected to the units need to be
associated with their corresponding commodities, see [node\_\_commodity](@ref).
