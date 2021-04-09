Indicates the end of this temporal block. The main use of this parameter is to create an offset from the model start. The default value is equal to a duration of 0. It is useful to distinguish here between two cases: a single solve, or a rolling window optimization.

**single solve**
When a Date time value is chosen, this is directly the end of the optimization for this temporal block. In a single solve optimization, a combination of `block_start` and `block_end` can easily be used to run optimizations that cover only part of the model horizon. Multiple `temporal_block` objects can then be used to create optimizations for disconnected time periods, which is commonly used in the method of representative days.

**rolling window optimization**
To create a temporal block that is rolling along with the optimization window, a rolling temporal block, a duration value should be chosen. The `block_end` parameter will in this case determine the size of the optimization window, with respect to the start of each optimization window. If multiple temporal blocks with different `block_end` parameters exist, the maximum value will determine the size of the optimization window. Note, this is different from the `roll_forward` parameter, which determines how much the window moves for after each optimization. For more info, see [One single `temporal_block`](@ref).


To create a static temporal_block, that doesn't move along with the rolling optimization window, the `block_end` needs to be defined as a `DateTime` value. #TODO: this is not yet supported
