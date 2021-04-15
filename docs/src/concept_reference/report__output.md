The [report\_\_output](@ref) relationship tells which [output](@ref) [variables](@ref Variables) to include
in which [report](@ref) when writing *SpineOpt* output.
Note that the [report](@ref)s also need to be connected to a [model](@ref) using the [model\_\_report](@ref) relationship.
Without appropriately defined [model\_\_report](@ref) and [report\_\_output](@ref) and relationships,
*SpineOpt* doesn't write any output, so be sure to include at least one [report](@ref)
connected to all the [output](@ref) [variables](@ref Variables) of interest in the [model](@ref)!