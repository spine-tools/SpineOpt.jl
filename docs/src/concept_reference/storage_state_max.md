The [storage\_state\_max](@ref) parameter represents the maximum allowed value for the `node_state` variable.
Note that in order for a [node](@ref) to have a `node_state` variable in the first place,
the [node\_type](@ref) parameter must be set to `storage\_node` or `storage\_group`.
However, if the [node](@ref) has storage investments enabled using the [candidate\_storages](@ref) parameter,
the [storage\_state\_max](@ref) parameter acts as a coefficient for the `storages_invested_available` variable.
Essentially, with investments,
the [storage\_state\_max](@ref) parameter represents *storage capacity per storage investment*.
