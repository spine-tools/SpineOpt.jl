`unit__investment_temporal_block` is a two-dimensional relationship between a [unit](@ref) and a [temporal_block](@ref). This relationship defines the temporal resolution and scope of a unit's investment decision. Note that in a decomposed investments problem with two model objects, one for the master problem model and another for the operations problem model, the link to the specific model is made indirectly through the [model__temporal_block](@ref) relationship. If a [model\_\_default\_investment\_temporal_block](@ref) is specified and no `unit__investment_temporal_block` relationship is specified, the [model\_\_default\_investment\_temporal\_block](@ref) relationship will be used. Conversely if `unit__investment_temporal_block` is specified along with [model\_\_temporal\_block](@ref), this will override [model\_\_default\_investment\_temporal\_block](@ref) for the specified [unit](@ref).

See also [Investment Optimization](@ref)