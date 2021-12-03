Specifies the names of [temporal\_block](@ref) objects to use as representative periods for certain time ranges.
This indicates the model to define operational variables only for those representative periods,
and map variables from normal periods to representative ones.
The idea behind this is to reduce the size of the problem by using a reduced set of variables,
when one knows that some reduced set of time periods can be representative for a larger one.

**Note that only operational variables other than [node\_state](@ref) are sensitive to this parameter.**
In other words, the model always create `node_state` variables and investment variables for all
time periods, regardless of whether or not `representative_periods_mapping` is specified for any
`temporal_block`.

To use representative periods in your model, do the following:

1. Define one `temporal_block` for the 'normal' periods as you would do if you weren't
   using representative periods.
2. Define a set of `temporal_block` objects, each corresponding to one representative period.
3. Specify `representative_periods_mapping` for the 'normal' `temporal_block` as a *map*,
   from consecutive date-time values to the name of a representative `temporal_block`.
4. Associate all the above `temporal_block` objects to elements in your model
   (e.g., via [node\_\_temporal\_block](@ref) and/or [units\_on\_\_temporal\_block](@ref) relationships),
   to map their operational variables from normal periods, to the variable from the representative period.
   
See also [Representative days with seasonal storages](@ref).