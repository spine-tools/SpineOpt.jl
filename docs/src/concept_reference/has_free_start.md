[temporal\_block](@ref)s with `true` generate their own independent history,
meaning that any prior time slices do not affect their variables.
The main use of this feature is to allow certain [temporal\_block](@ref)s
to neglect time steps prior to their starting,
thus permitting them the titular "free start".