The `window_weight` parameter, defined for a [model](@ref) object, is used in the Benders decomposition algorithm
with representative periods. In this setup, the subproblem rolls over a series of possibly disconnected windows, 
corresponding to the representative periods. Each of these windows can have a different weight, for example,
equal to the fraction of the full model horizon that it represents. Chosing a good weigth can help the solution 
be more accurate.

To use weighted rolling representative periods Benders, do the following.

- Specify [roll\_forward](@ref) as an array of n duration values, so the subproblem rolls over representative periods.
- Specify `window_weight` as an array of n + 1 floating point values, representing the weight of each window.
Note that it the problem rolls n times, then you have n + 1 windows.
