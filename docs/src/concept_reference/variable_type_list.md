The `variable_type_list` holds the possible values for different variable types,
namely `none`, `linear`, `binary`, or `integer`.
`none` can be used to remove the variables from the model.

This parameter value list is used for a [connection]@(ref), [node]@(ref) storage or [unit]@(ref).
Investment decision are handled via the [investment\_variable\_type](@ref) (unit and connection) and [storage\_investment\_variable\_type](@ref) (node) parameters.
Units also include the [online\_variable\_type](@ref) and [outage\_variable\_type](@ref) parameters.