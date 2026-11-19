Indicates the end of this [temporal\_block](@ref).
If not given, the [temporal\_block](@ref) is extended to cover the current optimization window (see [window\_duration](@ref)).
It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**Single solve**
When a `date_time` value is chosen,
it is directly the end of this [temporal\_block](@ref).
Note that in a single solve optimization,
[block\_start](@ref) and [block\_end](@ref) can define optimizations that cover only part of the model horizon.
Multiple [temporal\_block](@ref) objects can then be used to create optimizations for disconnected time periods,
which is commonly used in the method of representative days.
The default value coincides with the [model\_end](@ref).

**Rolling window optimization**
To create a [temporal\_block](@ref) that is rolling along with the optimization window,
a `duration` value should be chosen.
The [block\_end](@ref) parameter will in this case determine the size of its optimization window,
with respect to the start of each optimization window.
If multiple temporal blocks with different [block\_end](@ref) parameters exist,
the maximum value will determine the size of the optimization window.
Note, this is different from the [roll\_forward](@ref) parameter,
which determines how much the window moves for after each optimization.
For more info, see [One single `temporal block`](@ref).
The default value is equal to the [roll\_forward](@ref) parameter.
