The [connection\_investment\_variable\_type](@ref) parameter represents the *type* of
the [connections\_invested\_available](@ref) decision variable.

The default value, `variable_type_integer`, means that only integer factors of the [connection\_capacity](@ref)
can be invested in. The value `variable_type_continuous` means that any fractional factor can also be invested in.
The value `variable_type_binary` means that only a factor of 1 or zero are possible.
