Fixes the number of invested storages available ([storages\_invested\_available](@ref var_storages_invested_available))
for a storage [node](@ref) in the first Benders iteration.
The first master problem then uses this value instead of optimising the investment,
and the first sub problem is solved with it. From the second iteration on, the master problem optimises
the investment freely.

This works as a starting guess, e.g. from an earlier run, and can reduce the number of iterations needed.
Without it, the first master problem has no information on operating costs yet,
so it only invests what other constraints require.

Only used when [model\_type](@ref) is `spineopt_benders`. See [Decomposition](@ref).
