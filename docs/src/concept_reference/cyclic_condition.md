The [cyclic\_condition](@ref) parameter is used to enforce that the storage level
at the end of the optimization window is higher or equal to the storage level
at the beginning optimization. If the [cyclic\_condition](@ref) parameter is set to [true](@ref boolean_value_list)
for a [node\_\_temporal\_block](@ref) relationship, and the [has\_state](@ref) parameter of the corrresponding [node](@ref) is set to [true](@ref boolean_value_list), the [constraint\_cyclic\_node\_state](@ref) will be triggered.
