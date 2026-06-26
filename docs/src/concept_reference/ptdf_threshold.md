Given a [connection](@ref) and a [node](@ref), the power transfer distribution factor (PTDF)
is the fraction of the flow injected into the [node](@ref) that will flow on the [connection](@ref).
[ptdf\_threshold](@ref) is the minimum absolute value of the PTDF that is considered meaningful.
Any value below this threshold (in absolute value) will be treated as zero.

The PTDFs are used to model DC power flow on certain [connection](@ref)s.
To model DC power flow on a [connection](@ref), set [monitoring\_active](@ref) to `true`.

In addition, define a [grid](@ref) with [physics\_type](@ref) set to either [ptdf\_physics](@ref grid_physics_list),
or [lodf\_physics](@ref grid_physics_list).
and associate that [grid](@ref) (via [node\_\_grid](@ref)) to both [connection](@ref)s' [node](@ref)s
(given by [connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)).
