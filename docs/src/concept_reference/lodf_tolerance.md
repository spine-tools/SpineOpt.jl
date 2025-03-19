Given two [connection](@ref)s, the line outage distribution factor (LODF) is
the fraction of the pre-contingency flow on the first one, that will flow on the second after the contingency.
[lodf\_tolerance](@ref) is the minimum absolute value of the LODF that is considered meaningful.
Any value below this tolerance (in absolute value) will be treated as zero.

The LODFs are used to model contingencies on some [connection](@ref)s and their impact on some other [connection](@ref)s.
To model contingencies on a [connection](@ref), set [contingency\_activate](@ref) to `true`;
to study the impact of such contingencies on another [connection](@ref), set [monitoring\_activate](@ref) to `true`.

In addition, define a [grid](@ref) with [physics\_type](@ref) set to [commodity\_physics\_lodf](@ref commodity_physics_list),
and associate that [grid](@ref) (via [node\_\_grid](@ref)) to both [connection](@ref)s' [node](@ref)s
(given by [connection\_\_to\_node](@ref) and [connection\_\_from\_node](@ref)).
