The linepack constant is a physical property of a connection representing a pipeline and holds information on how the linepack flexibility relates to pressures of the adjacent nodes.
If, and only if, this parameter is defined, the linepack flexibility of a pipeline can be modelled.
The existence of the parameter triggers the generation of the [constraint on line pack storage](@ref constraint_storage_line_pack). The [connection\_linepack\_constant](@ref) should always be defined on the tuple (connection pipeline, linepack storage node, node group (containing both pressure nodes, i.e. start and end of the pipeline)).
[See also](@ref pressure-driven-gas-transfer).
