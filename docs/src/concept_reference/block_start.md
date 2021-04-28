Indicates the start of this temporal block. The main use of this parameter is to create an offset from the model start. The default value is equal to a duration of 0. It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a Date time value is chosen, this is directly the start of the optimization for this temporal block. When a duration is chosen, it is added to the [model\_start](@ref) to obtain the start of this [temporal\_block](@ref). In the case of a duration, the chosen value directly marks the offset of the optimization with respect to the [model\_start](@ref). The default value for this parameter is the [model\_start](@ref).

**rolling window optimization**
To create a temporal block that is rolling along with the optimization window, a rolling temporal block, a duration value should be chosen. The temporal [block\_start](@ref) will again mark the offset of the optimization start but now with respect to the start of each optimization window.
