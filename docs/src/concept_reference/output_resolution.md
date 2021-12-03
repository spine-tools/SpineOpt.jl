The [output\_resolution](@ref) parameter indicates the resolution at which [output](@ref) values should be reported.

If `null` (the default), then results are reported at the highest available resolution from the model.
If `output_resolution` is a duration value, then results are aggregated at that resolution before being reported.
At the moment, the aggregation is simply performed by taking the average value.
