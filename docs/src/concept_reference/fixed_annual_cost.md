Fixed annual operation and maintenance costs.

- For [connection](@ref)s: essentially, a cost coefficient on total available capacity, i.e. [capacity\_per\_connection](@ref) times ([existing\_connections](@ref) + [connections\_invested\_available](@ref var_connections_invested_available)).
  Value unit: e.g. in `EUR/MW/year`.
- For [node](@ref)s (storages): effectively, a cost coefficient on total available storage capacity, i.e. [storage\_state\_max](@ref)
  times ([existing\_storages](@ref) + [storages\_invested\_available](@ref var_storages_invested_available)).
  Value unit: e.g. in `EUR/MW/year`.

See [fom_cost](@ref) for [unit](@ref)s,
which is pending changes.
