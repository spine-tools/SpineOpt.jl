The [overwrite\_results\_on\_rolling](@ref) allows one to define whether or not results from further optimisation windows
should overwrite those from previous ones. This, of course, is relevant only if optimisation windows overlap,
which in turn happens whenever there is a [temporal\_block](@ref) that goes beyond the length of the window.

If `true` (the default) then results are written as a time-series.
If `false`, then results are written as a map from analysis time (i.e., the window start) to time-series.