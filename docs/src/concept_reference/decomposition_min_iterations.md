!!! warning
    EXPERIMENTAL

The minimum number of Benders iterations for a [model](@ref) with [model\_type](@ref) `spineopt_benders`.
The algorithm does not stop on [decomposition\_max\_gap](@ref) before this many iterations have been done.
[decomposition\_max\_iterations](@ref) still stops the algorithm in any case.
The default is 1, i.e. the algorithm can stop after the first iteration if the gap is small enough.

See [Decomposition](@ref).
