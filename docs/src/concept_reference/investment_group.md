The [investment\_group](@ref) class represents a group of investments that need to be done together.
For example, a storage investment on a [node](@ref) might only make sense if done together with a [unit](@ref)
or a [connection](@ref) investment.

To use this functionality, you must first create an [investment\_group](@ref) and then
specify any number of [unit\_\_investment\_group](@ref), [node\_\_investment\_group](@ref), and/or
[connection\_\_investment\_group](@ref) relationships between your [investment\_group](@ref)
and the [unit](@ref), [node](@ref), and/or [connection](@ref) investments that you want to be done together.
This will ensure that the investment variables of all the entities in the [investment\_group](@ref)
have the same value.
