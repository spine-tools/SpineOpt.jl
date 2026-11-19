Defines the _default_ length of the "window" (aka "horizon") of a single solve within
a "rolling horizon" (aka "receding horizon") optimization.
Effectively, each solve (aka "window") contains variables between
[model\_start](@ref) and [model\_start](@ref) + [window\_duration](@ref).
If [window\_duration](@ref) is not given,
[roll\_forward](@ref) will be used in its stead.
However, note that this is overwritten by individual [block\_end](@ref)s if defined.

Defined as a `duration` from [model\_start](@ref) for the initial solve,
and the starting time is then moved forward by [roll\_forward](@ref) each solve.
Results are saved sequentially for each [roll\_forward](@ref),
with the simulation stopping once the window start has rolled past [model\_end](@ref).

See the [Rolling horizon tutorial](@ref) for examples.