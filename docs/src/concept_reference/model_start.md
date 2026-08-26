Together with the [model\_end](@ref) parameter, it is used to define the temporal horizon of the model. For a single solve optimization, it marks the timestamp from which the relative offset in a [temporal\_block](@ref) is defined by the [block\_start](@ref) parameter. In the rolling optimization framework, it does this for the first optimization window.

A DateTime value should be chosen for this parameter. 
