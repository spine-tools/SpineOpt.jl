This parameter defines how much the optimization window rolls forward in a rolling horizon optimization and should be expressed as a duration. In a rolling horizon optimization, the model is split in windows that are optimized iteratively; `roll_forward` indicates how much the window should roll forward after each iteration. Overlap between consecutive optimization windows is possible. In the practical approaches presented in [Temporal Framework](@ref), the rolling window optimization will be explained in more detail. The default value of this parameter is the entire model time horizon, which leads to a single optimization for the entire time horizon.

In case you want your model to roll a different amount of time after each iteration, you can specify an array of durations for `roll_forward`. Position *i*th in this array indicates how much the model should roll after iteration *i*. This allows you to perform a rolling horizon optimization over a selection of disjoint representative periods as if they were contiguous.