For representative periods with seasonal storages, SpineOpt.jl can be interlinked with
the package SpinePeriods.jl.
SpinePeriods.jl provides the [representative\_periods\_mapping](@ref) parameter, which maps
each non-representative period of the whole optimization window to its representative [temporal\_block](@ref).
The map is organized as timeseries (indicating the start of each the non-representative period) with the names of the
representative temporal\_blocks as entries. 
