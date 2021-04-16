# Representative days with seasonal storages

In order to reduce computational times, representative periods are often used in optimization
models. However, this often limits the ability to properly account for seasonal storages.

In SpineOpt, we provide functionality to use representative days with seasonal storages
in combination with the package [**SpinePeriods.jl**](https://github.com/Spine-project/SpinePeriods.jl).

## [General idea](@id general_idea_rep_period_seasonal_Storage)

The general idea is to mimick the seasonal effects throughout a non-representative period,
e.g. a year of optimization, by introducing a specific sequence of the representative periods.
Taking the example of one year to be optimized with representative days and seasonal storages,
[**SpinePeriods.jl**](https://github.com/Spine-project/SpinePeriods.jl) provides a mapping
of each day of the year to its corresponding representative day. This information is
stored in the mapping parameter [representative\_periods\_mapping](@ref) and is defined
on the [temporal\_block](@ref) for the whole year. The [representative\_periods\_mapping](@ref)
parameter is a timeseries, pointing the beginning of each day to its corresponding
representative day [temporal\_block](@ref), which can also be automatically be generated through
**SpinePeriods.jl**.

In SpineOpt, this is interpreted in the following way:
- All operational variables, with the exception of the [node\_state](@ref) variable, are created
  for each representative period. For each non-representative period, the variables are mapped
  to their corresponding variable of the representative periods according to the [representative\_periods\_mapping](@ref)
  parameter.
- Only the [node\_state](@ref) variables and all investment [variables](@ref Variables) are created for both, representative and non-representative period (of course, depending on the existance of relationships to [temporal\_block](@ref)s).
