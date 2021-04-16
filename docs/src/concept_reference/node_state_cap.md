The [node\_state\_cap](@ref) parameter represents the maximum allowed value for the `node_state` variable.
Note that in order for a [node](@ref) to have a `node_state` variable in the first place,
the [has\_state](@ref) parameter must be set to `true`.
However, if the [node](@ref) has storage investments enabled using the [candidate\_storages](@ref) parameter,
the [node\_state\_cap](@ref) parameter acts as a coefficient for the `storages_invested_available` variable.
Essentially, with investments,
the [node\_state\_cap](@ref) parameter represents *storage capacity per storage investment*.
