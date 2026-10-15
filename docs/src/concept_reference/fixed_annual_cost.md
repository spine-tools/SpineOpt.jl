Fixed annual operation and maintenance costs.

- For [unit](@ref)s: essentially, a cost coefficient on total available capacity, i.e. [capacity\_per\_unit](@ref) times ([existing\_units](@ref) + [units\_invested\_available](@ref var_units_invested_available)).
  Value unit: e.g. in `EUR/MW/year`.
- For [connection](@ref)s: essentially, a cost coefficient on total available capacity, i.e. [capacity\_per\_connection](@ref) times ([existing\_connections](@ref) + [connections\_invested\_available](@ref var_connections_invested_available)).
  Value unit: e.g. in `EUR/MW/year`.
- For [node](@ref)s (storages): effectively, a cost coefficient on total available storage capacity, i.e. the `node\_state\_capacity` (product of [storage\_state\_max](@ref) and [storage\_state\_max\_fraction](@ref))
  times ([existing\_storages](@ref) + [storages\_invested\_available](@ref var_storages_invested_available)).
  Value unit: e.g. in `EUR/MW/year`.

By defining the [fixed\_annual\_cost](@ref) parameter for an entity, a cost term will be added to the objective function to account for the fixed operation and maintenance costs associated with that entity during the current optimization window. For [unit](@ref)s, [fixed\_annual\_cost](@ref) differs from [units\_on\_cost](@ref) in a way that the fixed operation and maintenance costs apply to both the online and offline unit.
