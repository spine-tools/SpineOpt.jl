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

## [Usage of representative days and seasonal storages for investment problems](@id Usage_rep_period_seasonal_Storage)
To make use of representative days with seasonal storages concept, multiple [temporal\_block](@ref) objects need to be created and connected to the system components, holding information about the resolutions in different parts of the model that come into play. As described in the section [Temporal Framework](@ref), every temporal block needs to be connected to a [model](@ref) object.
- **[temporal\_block](@ref) for investments**: In order to define the resolution of the investment decisions, a [temporal\_block](@ref) relecting the frequency of investment decisions should be introduced. For yearly investment, the [resolution](@ref) of this temporal block would be equal to `1Y`. In order to link [node](@ref)s, [unit](@ref)s or [connection](@ref)s to this investment resolution, the [node\_\_investment\_temporal_block](@ref), [unit\_\_investment\_temporal\_block](@ref), or [connection\_\_investment\_temporal_block](@ref) relationships need to be defined, respectively. For more details on investments, see also section [Investment Optimization](@ref)
- **[temporal\_block](@ref) for representative days**: For each representative day, one [temporal\_block](@ref) needs to be created, indicating the [block\_start](@ref) and [block\_end](@ref) of the representative day. The use of disconnected periods is also described in the section [Disconnected time periods](@ref). The resolution of the representative days corresponds to the resolution of the operational variables, e.g. `1h`. In order to associate operational variables with the representative periods, [node\_\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref) relationships need to be created. For convenience, it is also possible to create a group of all representative [temporal\_block](@ref)s and link this group to these relationships. Note that, when using **SpinePeriods.jl**, the representative temporal blocks are auto-generated.
 - **[temporal\_block](@ref) for non-representative days**: To introduce [node\_state](@ref) variables for the entire operational period, a temporal block overarching the entire horizon is created. Note that currently, this temporal block needs to have the same resolution as the representative days, e.g. `1h`. In order to associate operational variables with the representative periods, [node\_\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref) relationships need to be created. Note that, as described above, the non-representative variables, will be mapped to their corresponding representative days. To manually introduce the mapping between non-representative and representative periods, instead of using the recommended [**SpinePeriods.jl**](https://github.com/Spine-project/SpinePeriods.jl), the user must define the mapping parameter [representative\_periods\_mapping](@ref) by hand, consisting of `DateTime` indices (indicating the start of each non-representative period, e.g. for a daily mapping `2021-01-01T00:00:00`, `2021-01-02T00:00:00` etc.) and the name of the corresponding representative `temporal_block` as a value.
