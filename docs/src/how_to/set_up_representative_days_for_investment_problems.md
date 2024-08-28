# [How to set up representative days for investment problems](@id Usage_rep_period_seasonal_Storage)

Assuming you already have an investment model with a certain temporal structure that works, you can turn it into a representative periods model with the following steps.

!!! info
   Note that representative days often limit the ability to properly account for seasonal storages. However, SpineOpt takes this into account and allows for seasonal storage.

1. Select the representative periods. For example if you are modelling a year, you can select a few weeks
   (one in summer, one in winder, and one in mid season).
1. For each representative period, create a [temporal\_block](@ref) specifying [block\_start](@ref),
   [block\_end](@ref) and [resolution](@ref).
1. Associate these [temporal\_block](@ref)s to some [node](@ref)s and [unit](@ref)s in your system,
   via [node\_\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref) relationships.
1. Finally, for each **original** [temporal\_block](@ref) associated to the [node](@ref)s and [unit](@ref)s above,
   specify the value of the [representative\_periods\_mapping](@ref) parameter.
   This should be a `map` where each entry associates a date-time to the name of one
   of the **representative period** [temporal\_block](@ref)s created in step 3.
   More specifically, an entry with `t` as the key and `b` as the value means that time slices from the original block
   starting at `t`, are 'represented' by time slices from the `b` block.
   In other words, time slices between `t` and `t` plus the duration of `b` are represented by `b`.

In SpineOpt, this will be interpreted in the following way:
- For each [node](@ref) and [unit](@ref) associated to any of your representative [temporal\_block](@ref)s,
  the operational variables (with the exception of [node\_state](@ref)) will be created
  **only** for the representative periods. For the non-representative periods, SpineOpt will use the variable of
  the corresponding representative period according to the value of the [representative\_periods\_mapping](@ref)
  parameter.
- The [node\_state](@ref) variable and the investment [variables](@ref Variables) will be created for **all** periods,
  representative and non-representative.

The [**SpinePeriods.jl**](https://github.com/Spine-project/SpinePeriods.jl) package provides an alternative, perhaps simpler way
to setup a representative periods model based on the automatic selection and ordering of periods.
