Defines the length of the "window" (aka "horizon") of a single solve within
a "rolling horizon" (aka "receding horizon") optimization.
Effectively, each solve (aka "window") contains variables between
[model\_start](@ref) and [model\_start](@ref) + [window\_duration](@ref).

Defined as a `Duration` from [model\_start](@ref) for the initial solve,
and the starting time is then moved forward by [roll\_forward](@ref) each solve.
Results are saved sequentially for each [roll\_forward](@ref),
with the simulation stopping once the window start has rolled past [model\_end](@ref).

See the [Rolling horizon tutorial](@ref) for examples.