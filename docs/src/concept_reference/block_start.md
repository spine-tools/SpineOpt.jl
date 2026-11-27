Indicates the start of this [temporal\_block](@ref).
The main use of this parameter is to create an offset from the [model\_start](@ref).
The default value is interpreted equal to a duration of 0,
i.e. it equals [model\_start](@ref).
It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a `date_time` value is chosen,
this is directly the start of this [temporal\_block](@ref).
In the case of a `duration`,
it marks the offset of the optimization with respect to the [model\_start](@ref).

**rolling window optimization**
To create a [temporal\_block](@ref) that is rolling along with the optimization window, a duration value should be chosen.
The [block\_start](@ref) will again mark the offset of the optimization start but now with respect to the start of each optimization window.
