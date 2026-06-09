The [storage\_self\_discharge](@ref) parameter allows setting self-discharge losses for [node](@ref)s
with the [node\_state](@ref var_node_state) variables enabled using the [storage\_active](@ref) parameter.
Effectively, the [storage\_self\_discharge](@ref) parameter acts as a coefficient on the [node\_state](@ref var_node_state) variable in the
[node injection constraint](@ref constraint_node_injection), imposing losses for the [node](@ref).
In simple cases, storage losses are typically fractional,
e.g. a [storage\_self\_discharge](@ref) parameter value of 0.01 would represent 1% of [node\_state](@ref var_node_state) lost per unit of time.
However, a more general definition of what the [storage\_self\_discharge](@ref) parameter represents in *SpineOpt*
would be *loss power per unit of [node\_state](@ref var_node_state)*.
