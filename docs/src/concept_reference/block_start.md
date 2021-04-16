Indicates the start of this temporal block. The main use of this parameter is to create an offset from the model start. The default value is equal to a duration of 0. It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a Date time value is chosen, this is directly the start of the optimization for this temporal block. When a duration is chosen, it is added to the [model_start](@ref) to obtain the start of this [temporal_block](@ref). In the case of a duration, the chosen value directly marks the offset of the optimization with respect to the `model_start`. The default value for this parameter is the `model_start`.

**rolling window optimization**
To create a temporal block that is rolling along with the optimization window, a rolling temporal block, a duration value should be chosen. The temporal `block_start` will again mark the offset of the optimization start but now with respect to the start of each optimization window.

To create a static temporal block, that has a fixed `block_start` (and [block_end](@ref)) and does not move along with the rolling window but rather splats into the rolling window, once the rolling window hits the start of the static temporal_block, the `block_start` parameter needs to be defined as a `DateTime` value. #TODO: this is not supported yet!
