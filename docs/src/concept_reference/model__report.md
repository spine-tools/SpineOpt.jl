The [model\_\_report](@ref) relationship tells which [report](@ref)s are written by which [model](@ref),
where the contents of the [report](@ref)s are defined separately using the [report\_\_output](@ref) relationship.
Without appropriately defined [model\_\_report](@ref) and [report\_\_output](@ref) and relationships,
*SpineOpt* doesn't write any output, so be sure to include at least one [report](@ref)
connected to all the [output](@ref) [variables](@ref Variables) of interest in the [model](@ref)!