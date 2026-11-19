This parameter defines how much the optimization window rolls forward in a rolling horizon optimization and should be expressed as a `duration`.
In a rolling horizon optimization,
the model is split in windows that are optimized iteratively;
[roll\_forward](@ref) indicates how much the window should roll forward after each iteration.
In the practical approaches presented in [Temporal Framework](@ref),
the rolling window optimization will be explained in more detail.

If not given, [roll\_forward](@ref) will default to cover the entire model time span,
which leads to a single optimization.
The length of each rolling optimization window is primarily defined by [window\_duration](@ref) and [block\_end](@ref)s.
However, if neither of the above are given,
[roll\_forward](@ref) will also set the length of each window.

In case you want your model to roll a different amount of time after each iteration,
you can specify an array of durations for [roll\_forward](@ref).
Position *i*th in this array indicates how much the model should roll after iteration *i*.
This allows you to perform a rolling horizon optimization over a selection of disjoint representative periods as if they were contiguous.